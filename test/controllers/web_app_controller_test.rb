require 'test_helper'

class WebAppControllerTest < ActionDispatch::IntegrationTest
  test 'should get main' do
    get '/'
    assert_response :success
  end

  test 'should get random bad url' do
    get '/doesnteverexistnoiteverwontthankyou/asoeur/aou'
    assert_response :success
  end
end
