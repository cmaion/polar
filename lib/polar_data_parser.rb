require 'date'
require 'zlib'

require "#{File.dirname(__FILE__)}/protobuf/types.pb"
require "#{File.dirname(__FILE__)}/protobuf/structures.pb"
require "#{File.dirname(__FILE__)}/protobuf/user_physdata.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_sensors.pb"
require "#{File.dirname(__FILE__)}/protobuf/sport.pb"
require "#{File.dirname(__FILE__)}/protobuf/training_session.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_base.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_laps.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_stats.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_rr_samples.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_samples.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_route.pb"
require "#{File.dirname(__FILE__)}/protobuf/fitnesstestresult.pb"
require "#{File.dirname(__FILE__)}/protobuf/rr_recordtestresult.pb"
require "#{File.dirname(__FILE__)}/protobuf/dailysummary.pb"
require "#{File.dirname(__FILE__)}/protobuf/act_samples.pb"
require "#{File.dirname(__FILE__)}/protobuf/recovery_times.pb"
require "#{File.dirname(__FILE__)}/protobuf/swimming_samples.pb"
require "#{File.dirname(__FILE__)}/protobuf/sleepanalysisresult.pb"

module PolarDataParser
  def self.parse_user_physdata(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'PHYSDATA.BPB' }.first
      parsed[:phys] = PolarData::PbUserPhysData.parse(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_training_session(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }
    if training_session_file = files_in_dir.select { |f| f == 'TSESS.BPB' }.first
      parsed[:training_session] = PolarData::PbTrainingSession.parse(File.open(File.join(dir, training_session_file), 'rb').read)
    end

    dir = dir + "/00"
    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if sport_file = files_in_dir.select { |f| f == 'SPORT.BPB' }.first
      parsed[:sport] = PolarData::PbSport.parse(File.open(File.join(dir, sport_file), 'rb').read)
    end

    if sensors_file = files_in_dir.select { |f| f == 'SENSORS.BPB' }.first
      parsed[:sensors] = PolarData::PbExerciseSensors.parse(File.open(File.join(dir, sensors_file), 'rb').read)
    end

    if exercise_file = files_in_dir.select { |f| f == 'BASE.BPB' }.first
      parsed[:exercise] = PolarData::PbExerciseBase.parse(File.open(File.join(dir, exercise_file), 'rb').read)
    end

    if exercise_laps_file = files_in_dir.select { |f| f == 'LAPS.BPB' }.first
      parsed[:exercise_laps] = PolarData::PbLaps.parse(File.open(File.join(dir, exercise_laps_file), 'rb').read)
    end

    if exercise_stats_file = files_in_dir.select { |f| f == 'STATS.BPB' }.first
      parsed[:exercise_stats] = PolarData::PbExerciseStatistics.parse(File.open(File.join(dir, exercise_stats_file), 'rb').read)
    end

    if swim_file = files_in_dir.select { |f| f == 'SWIMSAMP.BPB' }.first
      parsed[:swimming_samples] = PolarData::PbSwimmingSamples.parse(File.open(File.join(dir, swim_file), 'rb').read)
    end

    route_pid = nil
    if route_file = files_in_dir.select { |f| f == 'ROUTE.GZB' }.first
      # Parse route in a different process to parallelize on a second CPU core
      route_read, route_write = IO.pipe
      route_pid = fork do
        route_read.close
        route_result = PolarData::PbExerciseRouteSamples.parse(Zlib::GzipReader.new(File.open(File.join(dir, route_file), 'rb')).read)
        Marshal.dump(route_result, route_write)
      end
      route_write.close
    end

    if samples_file = files_in_dir.select { |f| f == 'SAMPLES.GZB' }.first
      parsed[:samples] = PolarData::PbExerciseSamples.parse(Zlib::GzipReader.new(File.open(File.join(dir, samples_file), 'rb')).read)
    end

    if route_pid
      route_result = route_read.read
      Process.wait(route_pid)
      parsed[:route_samples] = Marshal.load(route_result)
    end

    parsed
  end

  def self.parse_fitness_test_result(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'FTRES.BPB' }.first
      parsed[:result] = PolarData::PbFitnessTestResult.parse(File.open(File.join(dir, file), 'rb').read)
    end

    if samples_file = files_in_dir.select { |f| f == 'SAMPLES.GZB' }.first
      parsed[:samples] = PolarData::PbExerciseSamples.parse(Zlib::GzipReader.new(File.open(File.join(dir, samples_file), 'rb')).read)
    end

    if file = files_in_dir.select { |f| f == 'RR.GZB' }.first
      parsed[:rr] = PolarData::PbExerciseRRIntervals.parse(Zlib::GzipReader.new(File.open(File.join(dir, file), 'rb')).read)
    end

    parsed
  end

  def self.parse_rr_recording_result(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'RRRECRES.BPB' }.first
      parsed[:result] = PolarData::PbRRRecordingTestResult.parse(File.open(File.join(dir, file), 'rb').read)
    end

    if file = files_in_dir.select { |f| f == 'RR.GZB' }.first
      parsed[:rr] = PolarData::PbExerciseRRIntervals.parse(Zlib::GzipReader.new(File.open(File.join(dir, file), 'rb')).read)
    end

    parsed
  end

  def self.parse_daily_summary(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'DSUM.BPB' }.first
      parsed[:summary] = PolarData::PbDailySummary.parse(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_activity_samples(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'ASAMPL0.BPB' }.first
      parsed[:samples] = PolarData::PbActivitySamples.parse(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_recovery_times(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'RECOVS.BPB' }.first
      parsed[:recovery] = PolarData::PbRecoveryTimes.parse(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_sleep_analysis(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'SLEEPRES.BPB' }.first
      parsed[:sleep] = PolarData::PbSleepAnalysisResult.parse(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end
end

def pb_sysdatetime_to_string sysdatetime, time_zone_offset = 0
  sysdatetime.date.year > 0 ? DateTime.new(sysdatetime.date.year, sysdatetime.date.month, sysdatetime.date.day, sysdatetime.time.hour, sysdatetime.time.minute, sysdatetime.time.seconds, "%+i" % (time_zone_offset / 60)).to_time.to_s : 'N/D'
end

def pb_localdatetime_to_string localdatetime
  localdatetime.date.year > 0 ? DateTime.new(localdatetime.date.year, localdatetime.date.month, localdatetime.date.day, localdatetime.time.hour, localdatetime.time.minute, localdatetime.time.seconds, "%+i" % ((localdatetime.time_zone_offset || 0) / 60)).to_time.to_s : 'N/D'
end

def pb_duration_to_string duration
  "#{"%02i" % duration.hours}:#{"%02i" % duration.minutes}:#{"%02i" % duration.seconds}.#{"%03i" % duration.millis}"
end

def pb_duration_to_float duration
  duration.hours.to_f * 3600 + duration.minutes * 60 + duration.seconds + duration.millis.to_f / 1000
end

def pb_date_to_string date
  "#{"%02i" % date.day}/#{"%02i" % date.month}/#{"%04i" % date.year}"
end

def min_per_km_2_m_per_s(val)
  val == 0 ? 0 : 1000.0 / (val * 60)
end

def kcal2joules(val)
  val * 4186.8
end

def degree2radian(deg)
  deg.to_f * Math::PI / 180.0
end

