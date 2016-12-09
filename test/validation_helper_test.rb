require_relative './test_helper'
require_relative '../validation_helper'

class ValidationHelperTest < Minitest::Test
  include ValidationHelper

  def test_form_validation_errors_valid_inputs
    self.expects(:csv_validation_errors)
        .with({:tempfile => 'test.csv'})
        .returns([])
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
      "Please select an enrollment term",
      "Email for sending results not found. Please update your Canvas contact info.",
      "Please attach enrollment data CSV file"
    ]

    assert_equal expected, form_validation_errors(params, session)
  end

  def test_form_validation_csv_errors
    csv_errors = ['Bad CSV', 'No data!']
    self.expects(:csv_validation_errors)
        .with({:tempfile => 'test.csv'})
        .returns(csv_errors)
    params = {
      'enrollment-data-file' => {:tempfile => 'test.csv'},
      'enrollment-term-id' => '75'
    }
    session = { 'user_email' => 'test@example.com' }

    assert_equal csv_errors, form_validation_errors(params, session)
  end
end
