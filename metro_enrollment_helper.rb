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

  def parse_csv(file)
    rows = []
    CSV.read(file, {:headers => true}).each do |row|
      required = MetroEnrollmentApp::REQUIRED_CSV_HEADERS
      row = row.to_h

      if required.detect{|header| !row.keys.include?(header)}
        raise CSV::MalformedCSVError, 'Some required field names are missing'
      end

      if required.detect{|header| !row[header] || row[header].to_s.empty?}
        raise CSV::MalformedCSVError, 'Some required data fields are blank'
      end

      rows << row
    end

    rows
  end
end
