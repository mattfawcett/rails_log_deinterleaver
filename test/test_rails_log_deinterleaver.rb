gem 'minitest'
require 'minitest/autorun'
require 'rails_log_deinterleaver'

class RailsLogDeinterleaverTest < MiniTest::Test
  def setup
    @deinterleaver = RailsLogDeinterleaver.new('')
  end

  def test_pid_for_line
    line = 'Aug 16 06:24:59 rails0 myapp[16983]: Processing by UsersController#index as JSON'
    assert_equal 16983, @deinterleaver.pid_for_line(line)
  end

  def test_time_for_line
    line = 'Aug 16 06:24:59 rails0 myapp[16983]: Processing by UsersController#index as JSON'
    assert_equal DateTime.new(Time.now.year,8,16,6,24,59), @deinterleaver.time_for_line(line)
  end
end
