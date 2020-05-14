require 'libusb'

module PolarUsb
  class PolarUsbError < StandardError; end
  class PolarUsbNotImplemented < StandardError; end
  class PolarUsbDeviceNotFound < StandardError; end
  class PolarUsbDeviceError < PolarUsbError; end
  class PolarUsbProtocolError < PolarUsbError
    def initialize(message, packet)
      @packet = packet
      super message
    end

    def to_s
      "#{super}\nPACKET: #{@packet.map { |i| i.to_s(16) }.join(' ')}"
    end
  end

  def self.detect
    controller = nil
    controller = begin
                   # Older Polar watches (V800)
                   HidController.new
                 rescue PolarUsbDeviceNotFound
                   nil
                 end
    controller ||= begin
                     # Newer Polar watches (Vantage)
                     AcmController.new
                   rescue PolarUsbDeviceNotFound
                     nil
                   end
    controller
  end

  class BaseController
    attr_accessor :product
    attr_accessor :serial_number

    def initialize
      raise PolarUsbNotImplemented.new
    end

    def request(data = nil)
      raise PolarUsbNotImplemented.new
    end

    def read
      raise PolarUsbNotImplemented.new
    end
  end
end

require_relative "polar_usb_hid"
require_relative "polar_usb_acm"
