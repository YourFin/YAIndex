require 'test_helper'

class FilesControllerTest < ActionDispatch::IntegrationTest
  test 'should get list' do
    get '/files/list'
    assert_response :success
  end
end
