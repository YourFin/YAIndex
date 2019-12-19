require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  test "should not save request without any text" do
    request = Request.new
    assert_not request.save, "Saved the request without any text"
  end
end
