module MetroEnrollmentHelper
  include WolfCore::Helpers
  class QueryError < StandardError; end
  class ApiError < StandardError; end

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
      row = row.to_h
      required = if self.class::const_defined?(:REQUIRED_CSV_HEADERS)
        self.class::REQUIRED_CSV_HEADERS
      else
        []
      end

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

  def find_or_create_user(row)
    find_user_redshift(row) || find_user_api(row) || create_user(row)
  end

  def find_user_redshift(row)
    query_string = %{
      SELECT
        distinct user_dim.canvas_id
      FROM
        pseudonym_dim
      JOIN user_dim
        ON user_dim.id = pseudonym_dim.user_id
      WHERE
        sis_user_id = 'metro_#{row['id']}' OR
        sis_user_id = 'Metro_#{row['id']}' OR
        unique_name = 'metro_#{row['id']}' OR
        unique_name = 'Metro_#{row['id']}' OR
        unique_name = '#{row['email']}';
    }

    results = canvas_data(query_string)
    if results.count > 1
      raise QueryError, "Multiple users found"
    else
      results.collect{|user| user['canvas_id']}.first
    end
  end

  def find_user_api(row)
    url = "accounts/#{settings.canvas_account_id}/users?search_term=metro_#{row['id']}"
    response = canvas_api.get(url)

    if response.status != 200
      raise ApiError, "API error while searching users: #{response.body}"
    elsif response.body.count > 1
      raise QueryError, 'Multiple users found'
    else
      response.body.collect{|user| user['id']}.first
    end
  end

  def create_user(row)
    payload = {
      'user' => {
        'name' => "#{row['first_name'].capitalize} #{row['last_name'].capitalize}",
      },
      'communication_channel' => {
        'type' => 'email',
        'address' => row['email'],
      },
      'pseudonym' => {
        'unique_id' => row['email'],
        'sis_user_id' => "metro_#{row['id']}",
        'send_confirmation' => true
      }
    }
    response = canvas_api.post("accounts/#{settings.canvas_account_id}/users", payload)
    if response.status != 200
      raise ApiError, "API error while creating user: #{response.body}"
    else
      response.body['id']
    end
  end
end
