require 'test_helper'

class RequestsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get requests_new_url
    assert_response :success
  end

  test "should get list" do
    get requests_list_url
    assert_response :success
  end

end
