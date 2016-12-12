module MetroEnrollmentHelper
  def form_validation_errors(params, session)
    errors = []

    if params['enrollment-term-id'].nil?
      errors << 'Please select an enrollment term'
    end

    if session['user_email'].nil? || session['user_email'].empty?
      errors << 'Email for sending results not found. Please update your Canvas contact info.'
    end

    if params['enrollment-data-file'].nil? || params['enrollment-data-file'].empty?
      errors << 'Please attach enrollment data CSV file'
    end

    errors
  end

  def parse_csv(csv_params)
    return []
  end
end
