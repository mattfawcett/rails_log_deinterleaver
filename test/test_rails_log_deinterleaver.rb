gem 'minitest'
require 'minitest/autorun'
require 'rails_log_deinterleaver'
require 'timeout'
require 'thread'
require 'stringio'
Thread.abort_on_exception = true

class RailsLogDeinterleaverTest < MiniTest::Test
  def setup
    @output = StringIO.new
    @tempfile = Tempfile.new('rails.log')
    @deinterleaver = RailsLogDeinterleaver::Parser.new(@tempfile.path, request_timeout: 2, output: @output)
  end

  def test_pid_for_line
    line = 'Aug 16 06:24:59 rails0 myapp[16983]: Processing by UsersController#index as JSON'
    assert_equal 16983, @deinterleaver.pid_for_line(line)
  end

  def test_time_for_line
    line = 'Aug 16 06:24:59 rails0 myapp[16983]: Processing by UsersController#index as JSON'
    assert_equal DateTime.new(Time.now.year,8,16,6,24,59), @deinterleaver.time_for_line(line)
  end

  def test_standard_usage
    raw = [
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Completed 200 OK in 18.2ms (Views: 17.4ms | ActiveRecord: 0.0ms)',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
      'Aug 16 06:24:59 rails0 myapp[2000]: Started GET "/page3" for 127.0.0.1 at 2015-08-16 06:24:59 -0400',
      'Aug 16 06:24:59 rails0 myapp[2000]: Processing by StaticController#page3 as HTML',
      'Aug 16 06:24:59 rails0 myapp[2000]: Completed 200 OK in 18.2ms (Views: 17.4ms | ActiveRecord: 0.0ms)',
    ]
    expected = [
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Completed 200 OK in 18.2ms (Views: 17.4ms | ActiveRecord: 0.0ms)',
      '',
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
      '',
      'Aug 16 06:24:59 rails0 myapp[2000]: Started GET "/page3" for 127.0.0.1 at 2015-08-16 06:24:59 -0400',
      'Aug 16 06:24:59 rails0 myapp[2000]: Processing by StaticController#page3 as HTML',
      'Aug 16 06:24:59 rails0 myapp[2000]: Completed 200 OK in 18.2ms (Views: 17.4ms | ActiveRecord: 0.0ms)',
      '', ''
    ]
    log_and_expect(raw, expected)
  end

  def test_should_ignore_lines_with_no_start
    raw = [
      'Aug 16 06:24:58 rails0 myapp[3000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Completed 200 OK in 18.2ms (Views: 17.4ms | ActiveRecord: 0.0ms)',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
    ]
    expected = [
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Completed 200 OK in 18.2ms (Views: 17.4ms | ActiveRecord: 0.0ms)',
      '',
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
      '', ''
    ]
    log_and_expect(raw, expected)
  end

  def test_should_not_log_requests_that_have_not_yet_finished
    raw = [
      'Aug 16 06:24:58 rails0 myapp[3000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
    ]
    expected = [
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
      '', ''
    ]
    log_and_expect(raw, expected)
  end

  def test_should_log_unfinished_requests_once_timeout_reached
    raw = [
      'Aug 16 06:24:58 rails0 myapp[3000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
    ]
    expected = [
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[1000]: Processing by StaticController#page1 as HTML',
      'Aug 16 06:24:58 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
      '',
      'Aug 16 06:24:58 rails0 myapp[2000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:58 rails0 myapp[2000]: Processing by StaticController#page2 as HTML',
      '', ''
    ]
    log_and_expect(raw, expected, 4)
  end

  def test_should_log_unfinished_request_if_new_request_comes_in_on_same_pid
    raw = [
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      'Aug 16 06:24:59 rails0 myapp[1000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:59 -0400',
      'Aug 16 06:24:59 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
    ]
    expected = [
      'Aug 16 06:24:58 rails0 myapp[1000]: Started GET "/page1" for 127.0.0.1 at 2015-08-16 06:24:58 -0400',
      '',
      'Aug 16 06:24:59 rails0 myapp[1000]: Started GET "/page2" for 127.0.0.1 at 2015-08-16 06:24:59 -0400',
      'Aug 16 06:24:59 rails0 myapp[1000]: Completed 200 OK in 20.2ms (Views: 19.4ms | ActiveRecord: 0.0ms)',
      '', ''
    ]
    log_and_expect(raw, expected)
  end

  private

  def log_and_expect(log_lines, expected_lines, timeout=1)
    out, error = nil, nil
    deinterleaver_thread = Thread.new do
      #out, error = capture_io do
        begin
          timeout(timeout) do
            @deinterleaver.run
          end
        rescue TimeoutError
        end
      #end
    end

    log_lines.each {|line| write_to_log(line) }

    deinterleaver_thread.join

    assert_equal(expected_lines.join("\n"), @output.string)
  end

  def write_to_log(line)
    @tempfile.puts line
    @tempfile.flush
  end
end
