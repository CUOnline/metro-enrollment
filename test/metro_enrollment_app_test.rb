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

  def test_post
    email = 'test@example.com'
    enrollment_term_id = '75'
    csv_rows = [[1,2,3],[4,5,6]]
    csv_file = 'test.csv'
    CSV.expects(:read).with(csv_file).returns(csv_rows)
    Resque.expects(:enqueue).with(MetroEnrollmentWorker, csv_rows, enrollment_term_id, email)

    login({:user_email => email})
    post '/', {'enrollment-data-file' => {:tempfile => csv_file}, 'enrollment-term-id' => enrollment_term_id}

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal MetroEnrollmentApp.mount_point, last_request.path
  end

  def test_post_unauthenticated
    post '/'

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/canvas-auth-login', last_request.path
  end

  def test_post_unauthorized
    login({'user_roles' => ['StudentEnrollment']})
    post '/'

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/unauthorized', last_request.path
  end
end
