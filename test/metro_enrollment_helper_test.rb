require_relative './test_helper'

class MetroEnrollmentHelperTest < Minitest::Test
  REQUIRED_CSV_HEADERS = MetroEnrollmentApp::REQUIRED_CSV_HEADERS
  def settings
    app.settings
  end

  include MetroEnrollmentHelper

  def test_form_validation_errors_valid_inputs
    params = {
      'enrollment-data-file' => {:tempfile => 'test.csv'},
      'enrollment-term-id' => '75'
    }
    session = { 'user_email' => 'test@example.com' }

    assert_equal [], form_validation_errors(params, session)
  end

  def test_form_validation_errors
    params = {
      'enrollment-data-file' => nil,
      'enrollment-term-id' => nil
    }
    session = { 'user_email' => nil }
    expected = [
      'Please select an enrollment term',
      'Email for sending results not found. Please update your Canvas contact info.',
      'Please attach enrollment data CSV file'
    ]

    assert_equal expected, form_validation_errors(params, session)
  end

  def test_parse_csv
    file = 'test.csv'
    headers = [
      'id', 'last name', 'first name', 'email',
      'course number', 'course code', 'section number'
    ]
    csv_rows = [
      CSV::Row.new(headers, [1,2,3,4,5,6,7]),
      CSV::Row.new(headers, [8,9,10,11,12,13,14])
    ]
    expected =[{
      'id'=>1,
      'last name'=>2,
      'first name'=>3,
      'email'=>4,
      'course number'=>5,
      'course code'=>6,
      'section number'=>7
    }, {
      'id'=>8,
      'last name'=>9,
      'first name'=>10,
      'email'=>11,
      'course number'=>12,
      'course code'=>13,
      'section number'=>14
    }]
    CSV.expects(:read).with(file, is_a(Hash)).returns(csv_rows)

    assert_equal expected, parse_csv(file)
  end

  def test_parse_csv_invalid_headers
    file = 'test.csv'
    headers = ['these', 'headers', 'are', 'missing', 'the', 'required', 'values']
    csv_rows = [
      CSV::Row.new(headers, [1,2,3,4,5,6,7]),
      CSV::Row.new(headers, [8,9,10,11,12,13,14])
    ]
    CSV.expects(:read).with(file, is_a(Hash)).returns(csv_rows)

    error = assert_raises CSV::MalformedCSVError do
      parse_csv(file)
    end

    assert_match (/field names are missing/), error.message
  end

  def test_parse_csv_missing_headers
    file = 'test.csv'
    headers = [
      'id', 'last name', 'first name', 'email',
      'course number', 'course code', 'section number'
    ]
    csv_rows = [
      CSV::Row.new(headers, [1,2,3,4,5,6,7]),
      CSV::Row.new(headers, [8,9,'','','',13,14])
    ]
    CSV.expects(:read).with(file, is_a(Hash)).returns(csv_rows)

    error = assert_raises CSV::MalformedCSVError do
      parse_csv(file)
    end

    assert_match (/fields are blank/), error.message
  end

  def test_find_user_api_existing
    account_id = 10
    user_id = 123
    app.settings.stubs(:canvas_account_id).returns(account_id)
    users = [{
      'id' => user_id
    }]
    stub_request(:get, /accounts\/#{account_id}\/users\?.+search_term=metro_#{user_id}/)
      .to_return(
        :body => users.to_json,
        :headers => {'Content-Type' => 'application/json', :link => []})

    assert_equal user_id, find_user_api({'id' => user_id})
  end

  def test_find_user_api_nonexistent
    user_id = 123
    stub_request(:get, /accounts\/#{@account_id}\/users\?.+search_term=metro_#{user_id}/)
      .to_return(
        :body => [].to_json,
        :headers => {'Content-Type' => 'application/json', :link => []})

    assert_nil find_user_api({'id' => user_id})
  end

  def test_find_user_api_multiple
    user_id = 123
    users = [{
      'id' => 123
    }, {
      'id' => 123
    }]
    stub_request(:get, /accounts\/#{@account_id}\/users\?.+search_term=metro_#{user_id}/)
      .to_return(
        :body => users.to_json,
        :headers => {'Content-Type' => 'application/json', :link => []})

    assert_raises MetroEnrollmentHelper::QueryError do
      find_user_api({'id' => user_id})
    end
  end

  def test_find_user_redshift_existing
    user_id = 123
    self.expects(:canvas_data).returns([{'canvas_id' => user_id}])
    assert_equal user_id, find_user_redshift({'id' => user_id})
  end

  def test_find_user_redshift_nonexistent
    user_id = 123
    self.expects(:canvas_data).returns([])
    assert_nil find_user_redshift({'id' => user_id})
  end

  def test_find_user_redshift_multiple
    user_id = 123
    self.expects(:canvas_data).returns([{'canvas_id' => user_id}, {'canvas_id' => 456}])
    assert_raises MetroEnrollmentHelper::QueryError do
      find_user_redshift({'id' => user_id})
    end
  end

  def test_create_user
    user = {
      'id' => 123,
      'email' => 'test@example.com',
      'first_name' => 'Test',
      'last_name' => 'Student'
    }
    stub_request(:post, /accounts\/#{@account_id}\/users/)
      .to_return(
        :body => user.to_json,
        :status => 200,
        :headers => {'Content-Type' => 'application/json', :link => []})

    assert_equal user['id'], create_user(user)
  end
end
