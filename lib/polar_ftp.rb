require 'fileutils'
require "#{File.dirname(__FILE__)}/polar_usb"
require "#{File.dirname(__FILE__)}/protobuf/types.pb"
require "#{File.dirname(__FILE__)}/protobuf/structures.pb"
require "#{File.dirname(__FILE__)}/protobuf/pftp_request.pb"
require "#{File.dirname(__FILE__)}/protobuf/pftp_response.pb"

class PolarFtp
  def initialize
    @polar_cnx = PolarUsb::Controller.new
  end

  def dir(remote_dir)
    # Directory listing
    if remote_dir[-1..-1] != '/'
      remote_dir += '/'
    end

    puts "Listing content of '#{remote_dir}'"
    result = @polar_cnx.request(
      PolarProtocol::PbPFtpOperation.new(
        :command => PolarProtocol::PbPFtpOperation::Command::GET,
        :path => remote_dir
      ).serialize_to_string)

    if result[0] == "\x00"
      puts "Error. Directory doesn't exists?"
      return nil
    end

    PolarProtocol::PbPFtpDirectory.parse(result)
  end

  def get(remote_file, output_file = nil)
    output_file ||= File.basename(remote_file)
    output_file = 'output' if output_file == '/'

    puts "Downloading '#{remote_file}' as '#{output_file}'"
    result = @polar_cnx.request(
      PolarProtocol::PbPFtpOperation.new(
        :command => PolarProtocol::PbPFtpOperation::Command::GET,
        :path => remote_file
      ).serialize_to_string)

    File.open(output_file, 'wb') do |f|
      f << result
    end
  end

  def sync(local_dir_root = nil)
    local_dir_root ||= File.expand_path(File.join("~", "Polar", @polar_cnx.serial_number))

    puts "Synchronizing to '#{local_dir_root}'"

    def recurse(local_dir_root, remote_dir)
      if content = self.dir(remote_dir)
        content.entries.each do |entry|
          if entry.name[-1..-1] == '/'
            # Sub directory
            recurse(local_dir_root, remote_dir + entry.name)
          else
            # File
            local_dir = local_dir_root + remote_dir
            local_file = local_dir + entry.name
            local_file_size = File.size(local_file) rescue -1
            if local_file_size != entry.size
              FileUtils.mkdir_p(local_dir)
              self.get(remote_dir + entry.name, local_file)
            end
          end
        end
      end
    end

    recurse local_dir_root, '/'
  end
end
