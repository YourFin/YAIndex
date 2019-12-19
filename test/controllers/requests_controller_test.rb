require 'test_helper'

class RequestsControllerTest < ActionDispatch::IntegrationTest
  test 'should get new' do
    get '/requests/new'
    assert_response :success
  end

  test 'should get list' do
    get '/requests/'
    assert_response :success
  end
end
