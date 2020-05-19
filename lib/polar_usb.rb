require 'libusb'

module PolarUsb
  class PolarUsbError < StandardError; end
  class PolarUsbNotImplemented < StandardError; end
  class PolarUsbNotPermitted < StandardError; end
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

  def self.detect(options)
    controller = nil
    controller = begin
                   # Older Polar watches (V800)
                   HidController.new(options)
                 rescue PolarUsbDeviceNotFound
                   nil
                 end
    controller ||= begin
                     # Newer Polar watches (Vantage)
                     AcmController.new(options)
                   rescue PolarUsbDeviceNotFound
                     nil
                   end
    controller
  end

  class BaseController
    attr_accessor :product
    attr_accessor :serial_number

    def initialize(options)
      raise PolarUsbNotImplemented.new
    end

    def request(data = nil)
      raise PolarUsbNotImplemented.new
    end

    def read
      raise PolarUsbNotImplemented.new
    end

    private

    def process_notification(data)
      case data[0]
      when 2
        STDERR.write "Notification received: idle\n"
      when 3
        STDERR.write "Notification received: battery status:#{data[2]}%\n"
      when 10
        STDERR.write "Notification received: push notification settings\n"
      else
        STDERR.write "Notification received: unknown (#{data.inspect})\n"
      end
    end

    def process_error(data)
      case data[0]
      when 0
        # Succeeded
      when 1
        raise PolarUsbError.new "Error: rebooting"
      when 2
        raise PolarUsbError.new "Error: try again"
      when 100
        raise PolarUsbError.new "Error: unidentified host error"
      when 101
        raise PolarUsbError.new "Error: invalid command"
      when 102
        raise PolarUsbError.new "Error: invalid parameter"
      when 103
        raise PolarUsbError.new "Error: no such file or directory"
      when 104
        raise PolarUsbError.new "Error: directory exists"
      when 105
        raise PolarUsbError.new "Error: file exists"
      when 106
        raise PolarUsbNotPermitted.new "Error: operation not permitted"
      when 107
        raise PolarUsbError.new "Error: no such user"
      when 108
        raise PolarUsbError.new "Error: timeout"
      when 200
        raise PolarUsbError.new "Error: unidentified device error"
      when 201
        raise PolarUsbError.new "Error: not implemented"
      when 202
        raise PolarUsbError.new "Error: system busy"
      when 203
        raise PolarUsbError.new "Error: invalid content"
      when 204
        raise PolarUsbError.new "Error: checksum failure"
      when 205
        raise PolarUsbError.new "Error: disk full"
      when 206
        raise PolarUsbError.new "Error: prerequisite not found"
      when 207
        raise PolarUsbError.new "Error: insufficient buffer"
      when 208
        raise PolarUsbError.new "Error: wait for idling"
      else
        raise PolarUsbError.new "Error: #{data[0]}?"
      end
    end
  end
end

require_relative "polar_usb_hid"
require_relative "polar_usb_acm"
