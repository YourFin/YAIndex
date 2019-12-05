require 'test_helper'

class WebAppControllerTest < ActionDispatch::IntegrationTest
  test 'should get main' do
    get web_app_main_url
    assert_response :success
  end
end
