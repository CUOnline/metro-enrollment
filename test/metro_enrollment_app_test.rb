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
    csv_params = {'tempfile' => 'test.csv'}
    app.any_instance.expects(:parse_csv).with(csv_params).returns(csv_rows)
    Resque.expects(:enqueue).with(MetroEnrollmentWorker, csv_rows, enrollment_term_id, email)
    app.any_instance.expects(:form_validation_errors).returns([])

    login({:user_email => email})
    post '/', {'enrollment-data-file' => csv_params, 'enrollment-term-id' => enrollment_term_id}

    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/', last_request.path
  end

  def test_post_validation_errors
    errors = ['Uh oh this is an error!', 'So is this']
    Resque.expects(:enqueue).never
    app.any_instance.expects(:form_validation_errors).returns(errors)

    login
    post '/'

    errors.each do |e|
      assert_match e, last_request.env['rack.session']['flash'][:danger]
    end
    assert_equal 302, last_response.status
    follow_redirect!
    assert_equal '/', last_request.path
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
