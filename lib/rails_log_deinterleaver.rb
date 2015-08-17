require 'rubygems'
require 'bundler/setup'
require 'date'
require 'file-tail'

class RailsLogDeinterleaver
  def initialize(filename, options={})
    @filename = filename
    @options = options
    @options[:request_timeout] ||= 30
    @options[:date_time_format] ||= "%b %d %H:%M:%S"
  end

  def run
    File.open(@filename) do |log|
      log.extend(File::Tail)
      log.interval = 10
      log.backward(10)
      log.tail do |line|
        process_line line
      end
    end
  end

  def process_line(line)
  end

  def pid_for_line(line)
    line.match(/\[(\d+)\]/).captures.first.to_i
  end

  def time_for_line(line)
    DateTime.strptime(line, @options[:date_time_format])
  end
end
