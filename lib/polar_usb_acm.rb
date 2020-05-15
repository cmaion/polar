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
      initial_packet = true
      size = 0
      response = []

      loop do
        packet = @serial.read(65536).bytes

        if packet.length == 0
          sleep 0.1
          next
        end

        if initial_packet
          raise PolarUsbProtocolError.new "Initial packet too short?", packet if packet.length < 3
          raise PolarUsbProtocolError.new "Unknown packet type #{packet[0]}?", packet if packet[0] != 5
          size = packet[1] + (packet[2] << 8)
          packet.shift(3)
          initial_packet = false
        end

        response += packet

        return response.pack("C*") if response.size == size

        raise PolarUsbProtocolError.new "Buffer overflow?", response if response.size > size
      end
    end
  end
end
