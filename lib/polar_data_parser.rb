require 'date'
require 'zlib'

$LOAD_PATH << "#{File.dirname(__FILE__)}/protobuf"

require "types_pb"
require "structures_pb"
require "user_physdata_pb"
require "exercise_sensors_pb"
require "sport_pb"
require "training_session_pb"
require "exercise_base_pb"
require "exercise_laps_pb"
require "exercise_stats_pb"
require "exercise_rr_samples_pb"
require "exercise_samples_pb"
require "exercise_route_pb"
require "fitnesstestresult_pb"
require "rr_recordtestresult_pb"
require "dailysummary_pb"
require "daily_training_load_pb"
require "act_samples_pb"
require "recovery_times_pb"
require "swimming_samples_pb"
require "sleepanalysisresult_pb"

module PolarDataParser
  def self.parse_user_physdata(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'PHYSDATA.BPB' }.first
      parsed[:phys] = PolarData::PbUserPhysData.decode(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_training_session(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }
    if training_session_file = files_in_dir.select { |f| f == 'TSESS.BPB' }.first
      parsed[:training_session] = PolarData::PbTrainingSession.decode(File.open(File.join(dir, training_session_file), 'rb').read)
    end

    dir = dir + "/00"
    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if sport_file = files_in_dir.select { |f| f == 'SPORT.BPB' }.first
      parsed[:sport] = PolarData::PbSport.decode(File.open(File.join(dir, sport_file), 'rb').read)
    end

    if sensors_file = files_in_dir.select { |f| f == 'SENSORS.BPB' }.first
      parsed[:sensors] = PolarData::PbExerciseSensors.decode(File.open(File.join(dir, sensors_file), 'rb').read)
    end

    if exercise_file = files_in_dir.select { |f| f == 'BASE.BPB' }.first
      parsed[:exercise] = PolarData::PbExerciseBase.decode(File.open(File.join(dir, exercise_file), 'rb').read)
    end

    if exercise_laps_file = files_in_dir.select { |f| f == 'LAPS.BPB' }.first
      parsed[:exercise_laps] = PolarData::PbLaps.decode(File.open(File.join(dir, exercise_laps_file), 'rb').read)
    end

    if exercise_auto_laps_file = files_in_dir.select { |f| f == 'ALAPS.BPB' }.first
      parsed[:exercise_auto_laps] = PolarData::PbAutoLaps.decode(File.open(File.join(dir, exercise_auto_laps_file), 'rb').read)
    end

    if exercise_stats_file = files_in_dir.select { |f| f == 'STATS.BPB' }.first
      parsed[:exercise_stats] = PolarData::PbExerciseStatistics.decode(File.open(File.join(dir, exercise_stats_file), 'rb').read)
    end

    if swim_file = files_in_dir.select { |f| f == 'SWIMSAMP.BPB' }.first
      parsed[:swimming_samples] = PolarData::PbSwimmingSamples.decode(File.open(File.join(dir, swim_file), 'rb').read)
    end

    if route_file = files_in_dir.select { |f| f == 'ROUTE.GZB' }.first
      parsed[:route_samples] = PolarData::PbExerciseRouteSamples.decode(Zlib::GzipReader.new(File.open(File.join(dir, route_file), 'rb')).read)
    end

    if samples_file = files_in_dir.select { |f| f == 'SAMPLES.GZB' }.first
      parsed[:samples] = PolarData::PbExerciseSamples.decode(Zlib::GzipReader.new(File.open(File.join(dir, samples_file), 'rb')).read)
    end

    parsed
  end

  def self.parse_fitness_test_result(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'FTRES.BPB' }.first
      parsed[:result] = PolarData::PbFitnessTestResult.decode(File.open(File.join(dir, file), 'rb').read)
    end

    if samples_file = files_in_dir.select { |f| f == 'SAMPLES.GZB' }.first
      parsed[:samples] = PolarData::PbExerciseSamples.decode(Zlib::GzipReader.new(File.open(File.join(dir, samples_file), 'rb')).read)
    end

    if file = files_in_dir.select { |f| f == 'RR.GZB' }.first
      parsed[:rr] = PolarData::PbExerciseRRIntervals.decode(Zlib::GzipReader.new(File.open(File.join(dir, file), 'rb')).read)
    end

    parsed
  end

  def self.parse_rr_recording_result(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'RRRECRES.BPB' }.first
      parsed[:result] = PolarData::PbRRRecordingTestResult.decode(File.open(File.join(dir, file), 'rb').read)
    end

    if file = files_in_dir.select { |f| f == 'RR.GZB' }.first
      parsed[:rr] = PolarData::PbExerciseRRIntervals.decode(Zlib::GzipReader.new(File.open(File.join(dir, file), 'rb')).read)
    end

    parsed
  end

  def self.parse_daily_summary(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'DSUM.BPB' }.first
      parsed[:summary] = PolarData::PbDailySummary.decode(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_daily_training_load(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'DAILYTLR.BPB' }.first
      parsed[:training_load] = PolarData::PbDailyTrainingLoad.decode(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_activity_samples(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'ASAMPL0.BPB' }.first
      parsed[:samples] = PolarData::PbActivitySamples.decode(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_recovery_times(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'RECOVS.BPB' }.first
      parsed[:recovery] = PolarData::PbRecoveryTimes.decode(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end

  def self.parse_sleep_analysis(dir)
    parsed = {}

    files_in_dir = Dir.glob("#{dir}/*").map { |f| f.sub(/^#{dir}\//, '') }

    if file = files_in_dir.select { |f| f == 'SLEEPRES.BPB' }.first
      parsed[:sleep] = PolarData::PbSleepAnalysisResult.decode(File.open(File.join(dir, file), 'rb').read)
    end

    parsed
  end
end

def pb_sysdatetime_to_string sysdatetime, time_zone_offset = 0
  sysdatetime.date.year > 0 ? DateTime.new(sysdatetime.date.year, sysdatetime.date.month, sysdatetime.date.day, sysdatetime.time.hour, sysdatetime.time.minute, sysdatetime.time.seconds, "%+i" % (time_zone_offset / 60)).to_time.to_s : 'N/D'
end

def pb_localdatetime_to_string localdatetime
  localdatetime && localdatetime.date.year > 0 ? DateTime.new(localdatetime.date.year, localdatetime.date.month, localdatetime.date.day, localdatetime.time.hour, localdatetime.time.minute, localdatetime.time.seconds, "%+i" % ((localdatetime.time_zone_offset || 0) / 60)).to_time.to_s : 'N/D'
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

