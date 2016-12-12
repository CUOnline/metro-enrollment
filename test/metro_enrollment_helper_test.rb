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
      "Please select an enrollment term",
      "Email for sending results not found. Please update your Canvas contact info.",
      "Please attach enrollment data CSV file"
    ]

    assert_equal expected, form_validation_errors(params, session)
  end
end
