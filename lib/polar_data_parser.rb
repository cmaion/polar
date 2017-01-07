require 'date'
require 'zlib'

require "#{File.dirname(__FILE__)}/protobuf/types.pb"
require "#{File.dirname(__FILE__)}/protobuf/structures.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_sensors.pb"
require "#{File.dirname(__FILE__)}/protobuf/sport.pb"
require "#{File.dirname(__FILE__)}/protobuf/training_session.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_base.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_laps.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_stats.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_rr_samples.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_samples.pb"
require "#{File.dirname(__FILE__)}/protobuf/exercise_route.pb"
require "#{File.dirname(__FILE__)}/protobuf/rr_recordtestresult.pb"

module PolarDataParser
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

    if samples_file = files_in_dir.select { |f| f == 'SAMPLES.GZB' }.first
      parsed[:samples] = PolarData::PbExerciseSamples.parse(Zlib::GzipReader.new(File.open(File.join(dir, samples_file), 'rb')).read)
    end

    if route_file = files_in_dir.select { |f| f == 'ROUTE.GZB' }.first
      parsed[:route_samples] = PolarData::PbExerciseRouteSamples.parse(Zlib::GzipReader.new(File.open(File.join(dir, route_file), 'rb')).read)
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
end
