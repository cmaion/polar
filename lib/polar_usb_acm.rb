require 'serialport'

module PolarUsb
  class AcmController < BaseController
    def initialize(options)
      @serial_dev = options[:device] || '/dev/ttyACM0'
      @usb_vendor = 0x0da4
      @usb_product = 0x0014

      @usb_context = LIBUSB::Context.new
      @device = @usb_context.devices(idVendor: @usb_vendor, idProduct: @usb_product).first
      raise PolarUsbDeviceNotFound.new "Could not find Polar USB device" unless @device

      self.product = @device.product
      self.serial_number = @device.serial_number

      begin
        @serial = SerialPort.new @serial_dev, { 'baud' => 115200, 'data_bits' => 8, 'stop_bits' => 1, 'parity' => 0 }
      rescue => e
        STDERR.write "#{self.product} serial #{self.serial_number} found, but couldn't open serial device on #{@serial_dev}: #{e}\nPlease specify the device to use with the -d option.\n"
        raise PolarUsbDeviceNotFound.new "Couldn't open Polar USB device on #{@serial_dev}: #{e}"
      end

      STDERR.write "Connected to #{self.product} serial #{self.serial_number}\n"

    rescue LIBUSB::ERROR_ACCESS
      raise PolarUsbDeviceError.new "No permission to access Polar USB device"
    rescue LIBUSB::ERROR_BUSY
      raise PolarUsbDeviceError.new "Polar USB device is busy"
    end

    # Packet structure:
    # . Byte 0: packet type/flags
    #     bit 0: initial packet
    #     bit 1: notification
    #     bit 2: 1
    #     bit 3: has more?
    # . Byte 1: payload length (lower byte)
    # . Byte 2: payload length (upper byte)

    def request(data = nil)
      packet = []
      packet[0] = 5
      packet[1] = data.length & 255
      packet[2] = data.length >> 8

      packet += data.bytes

      @serial.write packet.pack("C*")

      read
    end

    def read
      done = false
      expect_header = true
      started = false
      is_notification = false
      has_more = false
      initial_packet = false
      expected_size = 0
      received_size = 0
      packet = []
      response = []
      notification = []

      while !done || !packet.empty?
        if buffer = @serial.read(65536)
          packet += buffer.bytes
        end
        payload = nil

        if packet.length == 0
          sleep 0.001
          next
        end

        if expect_header
          raise PolarUsbProtocolError.new "Packet too short?", packet if packet.length < 3

          packet_flags = packet[0]
          initial_packet = packet_flags & 1 != 0
          is_notification = packet_flags & 2 != 0
          unknown_flag = packet_flags & 4 != 0
          has_more = packet_flags & 8 != 0

          expected_size = packet[1] + (packet[2] << 8)
          received_size = 0
          payload = packet[3..-1]

          if packet_flags == 1
            process_error payload
            next
          end

          raise PolarUsbProtocolError.new "Initial packet expected?", packet if !started && !initial_packet
          raise PolarUsbProtocolError.new "Initial packet not expected?", packet if initial_packet && started
          raise PolarUsbProtocolError.new "Unknown packet flag? #{packet_flags}", packet unless unknown_flag
          raise PolarUsbProtocolError.new "Unknown packet flags? #{packet_flags}", packet if packet_flags & 0xf0 != 0

          expect_header = false
          started = true

        else
          payload = packet
        end

        if (overflow = received_size + payload.size - expected_size) > 0
          # We have received more data than expected. Only consume what was expected and let next iteration process the remaining data.
          packet = payload.pop(overflow)
        else
          packet = []
        end
        received_size += payload.size

        if is_notification
          notification += payload
        else
          raise PolarUsbProtocolError.new "Received unexpected data after completion of previous transfer", payload if done
          response += payload
        end

        if received_size == expected_size
          expect_header = true
          if has_more
            @serial.write [ 8, 0, 0 ].pack("C*") # Ask more
          elsif is_notification
            process_notification notification
            notification = []
            started = false
          else
            started = false
            done = true
          end
        end
      end
      return response.pack("C*")
    end
  end
end
