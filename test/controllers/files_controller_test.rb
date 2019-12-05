require 'test_helper'

class FilesControllerTest < ActionDispatch::IntegrationTest
  test 'should get list' do
    get files_list_url
    assert_response :success
  end
end
