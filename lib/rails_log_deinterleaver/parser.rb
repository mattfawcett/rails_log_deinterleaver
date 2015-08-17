require 'date'
require 'file-tail'
require 'thread'

module RailsLogDeinterleaver
  class Parser
    def initialize(filename, options={})
      @filename = filename
      @options = options
      @options[:request_timeout] ||= 30
      @options[:date_time_format] ||= "%b %d %H:%M:%S"
      @options[:start_request_regex] ||= /\[\d+\]: Started/
      @options[:end_request_regex] ||= /\[\d+\]: Completed/
      @options[:output] ||= $stdout
      @pids = {}
    end

    def run
      Thread.new do
        self.ensure_timeouts_logged
      end

      File.open(@filename) do |log|
        log.extend(File::Tail)
        log.interval = 0.1
        log.backward(@options[:backward]) if @options[:backward]
        log.tail do |line|
          process_line line
        end
      end
    end

    def process_line(line)
      pid = pid_for_line(line)

      if line.match(@options[:start_request_regex])
        if @pids[pid]
          # Already a request started but not finished for this pid. (Should be rare)
          # Log what we have to start a new request
          output_logs_for_pid(pid)
        end

        @pids[pid] = {lines: []}
      end

      return unless @pids[pid]

      @pids[pid][:last_seen_at] = Time.now
      @pids[pid][:lines].push(line)

      if line.match(@options[:end_request_regex])
        output_logs_for_pid(pid)
      end
    end

    # Output all lines of the log for a single request,
    # followed by an empty blank line.
    def output_logs_for_pid(pid)
      @options[:output].puts (@pids[pid][:lines] << '')
      @pids.delete(pid)
    end

    def pid_for_line(line)
      line.match(/\[(\d+)\]/).captures.first.to_i
    end

    def time_for_line(line)
      DateTime.strptime(line, @options[:date_time_format])
    end

    def ensure_timeouts_logged
      expired_time = Time.now - @options[:request_timeout]
      @pids.each do |pid, details|
        if details[:last_seen_at] <= expired_time
          output_logs_for_pid(pid)
        end
      end

      sleep 1
      self.ensure_timeouts_logged
    end
  end
end
