require_relative './test_helper'

class MetroEnrollmentWorkerTest < Minitest::Test
  def test_perform
    enrollment_term_id = '75'
    email = 'test@example.com'
    rows = [{
      'id' => 123,
      'first name' => 'first',
      'last name' => 'last',
      'email' => 'test@msu.com',
      'course number' => 101,
      'course code' => 'CSCI',
      'course section' => '01'
    }, {
      'id' => 456,
      'first name' => 'first2',
      'last name' => 'last2',
      'email' => 'test2@msu.com',
      'course number' => 101,
      'course code' => 'CSCI',
      'course section' => '02'
    }, {
      'id' => 789,
      'first name' => 'first3',
      'last name' => 'last3',
      'email' => 'test3@msu.com',
      'course number' => 102,
      'course code' => 'BIO',
      'course section' => '01'
    }]
    rows.each_with_index do |row, index|
      user_id    = "user_id_#{index}"
      section_id = "section_id_#{index}"
      app.expects(:find_or_create_user).with(row).returns(user_id)
      app.expects(:find_section).with(row, enrollment_term_id).returns(section_id)
      app.expects(:enroll_user).with(user_id, section_id)
    end
    output_rows = [rows.first.keys + ['result message']] +
                  rows.map{|r| r.values + ['Enrollment successful']}
    app.expects(:send_output).with(email, output_rows)

    MetroEnrollmentWorker.perform(rows, enrollment_term_id, email)
  end

  def test_perform_with_errors
    enrollment_term_id = '75'
    email = 'test@example.com'
    rows = [{
      'id' => 123,
      'first name' => 'first',
      'last name' => 'last',
      'email' => 'test@msu.com',
      'course number' => 101,
      'course code' => 'CSCI',
      'course section' => '01'
    }, {
      'id' => 456,
      'first name' => 'first2',
      'last name' => 'last2',
      'email' => 'test2@msu.com',
      'course number' => 101,
      'course code' => 'CSCI',
      'course section' => '02'
    }, {
      'id' => 789,
      'first name' => 'first3',
      'last name' => 'last3',
      'email' => 'test3@msu.com',
      'course number' => 102,
      'course code' => 'BIO',
      'course section' => '01'
    }]

    app.expects(:find_or_create_user)
      .with(rows[0])
      .raises(MetroEnrollmentHelper::QueryError, "User Query Error")

    app.expects(:find_or_create_user).with(rows[1]).returns('user_id')
    app.expects(:find_section).with(rows[1], enrollment_term_id)
       .raises(MetroEnrollmentHelper::QueryError, "Section Query Error")

    app.expects(:find_or_create_user).with(rows[2]).returns('user_id')
    app.expects(:find_section).with(rows[2], enrollment_term_id).returns('section_id')
    app.expects(:enroll_user).with('user_id', 'section_id')
       .raises(MetroEnrollmentHelper::ApiError, "Enrollment Api Error")

    output_rows = [
      rows.first.keys + ['result message'],
      rows[0].values + ['User Query Error'],
      rows[1].values + ['Section Query Error'],
      rows[2].values + ['Enrollment Api Error']
    ]

    app.expects(:send_output).with(email, output_rows)
    MetroEnrollmentWorker.perform(rows, enrollment_term_id, email)
  end
end
