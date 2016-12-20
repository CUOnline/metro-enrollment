class MetroEnrollmentWorker
  @queue = 'metro-enrollment'

  def self.perform(csv_rows, enrollment_term_id, email)
    output_rows = [csv_rows.first.keys + ["result message"]]
    csv_rows.each do |row|
      begin
        user_id    = MetroEnrollmentApp.find_or_create_user(row)
        section_id = MetroEnrollmentApp.find_section(row, enrollment_term_id)
        MetroEnrollmentApp.enroll_user(user_id, section_id)
      rescue MetroEnrollmentHelper::QueryError, MetroEnrollmentHelper::ApiError => e
        row_message = e.message
      end

      row_message ||= 'Enrollment successful'
      output_rows << row.values + [row_message]
    end

    MetroEnrollmentApp.send_output(email, output_rows)
  end
end
