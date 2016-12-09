require_relative './test_helper'

class MetroEnrollmentAppTest < Minitest::Test
  def test_get
    login
    get '/'
    assert_equal 200, last_response.status
  end

  def test_get_unauthenticated
    get '/'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_get_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    get '/'
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end
end
