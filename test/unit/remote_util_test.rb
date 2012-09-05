require 'test_helper'
require 'remote_util'

class ProductTest < ActiveSupport::TestCase
  
  setup do
  end
  
  test "Basic do_with_retry (repeated failures)" do

    attempts = 0
    start_time = Time.now
    assert_raise(ArgumentError, "An ArgumentError was raised") {
      RemoteUtil.do_with_retry(interval: 1) { |except|
        if attempts == 0
          assert_nil except, "except is nil for first attempt"
        else
          assert except.is_a?(ArgumentError), "except is an ArgumentError for subsequent attempts"
        end
        attempts += 1
        raise ArgumentError
      }
    }
    end_time = Time.now - start_time
    assert (end_time > 1.5 and end_time < 2.5), "Elapsed time is between 1.5 and 2.5 seconds" 
    assert_equal 3, attempts

  end

  test "do_with_retry (success after 1 try)" do

    attempts = 0
    result = RemoteUtil.do_with_retry(max_tries: 3, interval: 0) {
      attempts += 1
      999
    }
    assert_equal 999, result
    assert_equal 1, attempts

  end

  test "do_with_retry (success after 2 tries)" do

    attempts = 0
    result = RemoteUtil.do_with_retry(max_tries: 3, interval: 0) {
      attempts += 1
      if attempts == 2
        999
      else 
        raise ArgumentError
      end
    }
    assert_equal 999, result
    assert_equal 2, attempts

  end

  test "do_with_retry specific exception list" do

    attempts = 0
    assert_raise(ArgumentError, "An ArgumentError was raised") {
      RemoteUtil.do_with_retry(max_tries: 3, interval: 0, exceptions: [ArgumentError, IOError]) {
        attempts += 1
        raise ArgumentError
      }
    }
    assert_equal 3, attempts

  end

  test "do_with_retry exception not in list" do

    attempts = 0
    assert_raise(ArgumentError, "An ArgumentError was raised") {
      RemoteUtil.do_with_retry(max_tries: 3, interval: 0, exceptions: IOError) {
        attempts += 1
        raise ArgumentError
      }
    }
    assert_equal 1, attempts

  end

end

