require_relative './test_helper'

class MetroEnrollmentHelperTest < Minitest::Test
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
      'course number', 'course_code', 'section_number'
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
      'course_code'=>6,
      'section_number'=>7
    }, {
      'id'=>8,
      'last name'=>9,
      'first name'=>10,
      'email'=>11,
      'course number'=>12,
      'course_code'=>13,
      'section_number'=>14
    }]
    CSV.expects(:read).with(file, {:headers => true}).returns(csv_rows)

    assert_equal expected, parse_csv(file)
  end

  def test_parse_csv_invalid_headers
    file = 'test.csv'
    headers = ['these', 'headers', 'are', 'missing', 'the', 'required', 'values']
    csv_rows = [
      CSV::Row.new(headers, [1,2,3,4,5,6,7]),
      CSV::Row.new(headers, [8,9,10,11,12,13,14])
    ]
    CSV.expects(:read).with(file, {:headers => true}).returns(csv_rows)

    error = assert_raises CSV::MalformedCSVError do
      parse_csv(file)
    end

    assert_match /field names are missing/, error.message
  end

  def test_parse_csv_invalid_headers
    file = 'test.csv'
    headers = [
      'id', 'last name', 'first name', 'email',
      'course number', 'course_code', 'section_number'
    ]
    csv_rows = [
      CSV::Row.new(headers, [1,2,3,4,5,6,7]),
      CSV::Row.new(headers, [8,9,'','','',13,14])
    ]
    CSV.expects(:read).with(file, {:headers => true}).returns(csv_rows)

    error = assert_raises CSV::MalformedCSVError do
      parse_csv(file)
    end

    assert_match /fields are blank/, error.message
  end
end
