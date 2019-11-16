require 'fileutils'

require_relative "polar_usb"
require_relative "polar_data_parser"

require "types_pb"
require "structures_pb"
require "pftp_request_pb"
require "pftp_response_pb"

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
      PolarProtocol::PbPFtpOperation.encode(
        PolarProtocol::PbPFtpOperation.new(
          :command => PolarProtocol::PbPFtpOperation::Command::GET,
          :path => remote_dir
        )
      )
    )

    if result[0] == "\x00"
      puts "Error. Directory doesn't exists?"
      return nil
    end

    PolarProtocol::PbPFtpDirectory.decode(result)
  end

  def get(remote_file, output_file = nil)
    output_file ||= File.basename(remote_file)
    output_file = 'output' if output_file == '/'
    output_file_part = "#{output_file}.part"

    puts "Downloading '#{remote_file}' as '#{output_file}'"
    result = @polar_cnx.request(
      PolarProtocol::PbPFtpOperation.encode(
        PolarProtocol::PbPFtpOperation.new(
          :command => PolarProtocol::PbPFtpOperation::Command::GET,
          :path => remote_file
        )
      )
    )

    File.open(output_file_part, 'wb') do |f|
      f << result
    end
    FileUtils.mv(output_file_part, output_file)
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

            up2date = local_file_size == entry.size

            if up2date
              if remote_dir =~ /\/DSUM\/$/
                # Daily summary size doesn't change, but content may.
                # So we inspect our local copy of the daily summary, and if we
                # have less than 24 hours recorded there, download again.
                parsed = PolarDataParser.parse_daily_summary(local_dir)
                if summary = parsed[:summary]
                  total_recorded_activity =
                    pb_duration_to_float(summary.activity_class_times.time_non_wear) +
                    pb_duration_to_float(summary.activity_class_times.time_sleep) +
                    pb_duration_to_float(summary.activity_class_times.time_sedentary) +
                    pb_duration_to_float(summary.activity_class_times.time_light_activity) +
                    pb_duration_to_float(summary.activity_class_times.time_continuous_moderate) +
                    pb_duration_to_float(summary.activity_class_times.time_intermittent_moderate) +
                    pb_duration_to_float(summary.activity_class_times.time_continuous_vigorous) +
                    pb_duration_to_float(summary.activity_class_times.time_intermittent_vigorous)
                  up2date = total_recorded_activity >= 24*3600
                end
              elsif remote_dir == "/" && entry.name == "SYNCINFO.BPB"
                # Always fetch newest files
                up2date = false
              elsif remote_dir =~ /^\/U\/[0-9]*\/(S|TL)\/$/
                # Always fetch newest files
                up2date = false
              end
            end

            unless up2date
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
