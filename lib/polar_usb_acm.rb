require 'rubyserial'

module PolarUsb
  class AcmController < BaseController
    def initialize
      @serial_dev = '/dev/ttyACM0'
      @usb_vendor = 0x0da4
      @usb_product = 0x0014

      @usb_context = LIBUSB::Context.new
      @device = @usb_context.devices(idVendor: @usb_vendor, idProduct: @usb_product).first
      raise PolarUsbDeviceNotFound.new "Could not find Polar USB device" unless @device

      @serial = Serial.new @serial_dev, 115200

      self.product = @device.product
      self.serial_number = @device.serial_number
      STDERR.write "Connected to #{self.product} serial #{self.serial_number}\n"

    rescue LIBUSB::ERROR_ACCESS
      raise PolarUsbDeviceError.new "No permission to access Polar USB device"
    rescue LIBUSB::ERROR_BUSY
      raise PolarUsbDeviceError.new "Polar USB device is busy"
    rescue RubySerial::Error => e
      raise PolarUsbDeviceError.new "Couldn't open Polar USB device on #{@serial_dev}: #{e}"
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
      expect_header = true
      started = false
      is_notification = false
      has_more = false
      initial_packet = false
      packet_expected_size = 0
      packet_received_size = 0
      response = []
      notification = []

      loop do
        packet = @serial.read(65536).bytes

        if packet.length == 0
          sleep 0.1
          next
        end

        if expect_header
          raise PolarUsbProtocolError.new "Packet too short?", packet if packet.length < 3

          initial_packet = packet[0] & 1 != 0
          raise PolarUsbProtocolError.new "Initial packet expected?", packet if !started && !initial_packet
          raise PolarUsbProtocolError.new "Initial packet not expected?", packet if initial_packet && started

          is_notification = packet[0] & 2 != 0

          unknown_flag = packet[0] & 4 != 0
          raise PolarUsbProtocolError.new "Unknown packet flag? #{packet[0]}", packet unless unknown_flag

          has_more = packet[0] & 8 != 0

          raise PolarUsbProtocolError.new "Unknown packet flag? #{packet[0]}", packet if packet[0] & 0xf0 != 0

          packet_expected_size = packet[1] + (packet[2] << 8)
          packet_received_size = 0
          packet.shift(3)

          expect_header = false
          started = true
        end

        if is_notification
          notification += packet
        else
          response += packet
        end

        packet_received_size += packet.size

        if packet_received_size == packet_expected_size
          if has_more
            @serial.write [ 8, 0, 0 ].pack("C*") # Ask more
            expect_header = true
          elsif is_notification
            process_notification notification
            notification = []
            expect_header = true
            started = false
          else
            return response.pack("C*")
          end

        elsif packet_received_size > packet_expected_size
          raise PolarUsbProtocolError.new "Buffer overflow?", packet
        end
      end
    end
  end
end
