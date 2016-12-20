require 'bundler/setup'
require 'wolf_core'
require 'csv'
require_relative './metro_enrollment_worker'
require_relative './metro_enrollment_helper'

class MetroEnrollmentApp < WolfCore::App
  set :title, 'MSU/CU Enrollment'
  set :root, File.dirname(__FILE__)
  set :logger, create_logger
  set :auth_paths, [/.*/]

  enable :exclude_js
  enable :exclude_css

  helpers MetroEnrollmentHelper

  REQUIRED_CSV_HEADERS = [
    'id', 'last name', 'first name', 'email',
    'course number', 'course code', 'section number'
  ]

  get '/' do
    slim :index
  end

  post '/' do
    errors = form_validation_errors(params, session)
    if errors.any?
      flash[:danger] = errors.join("\n")
    else
      begin
        rows = parse_csv(params['enrollment-data-file'][:tempfile])
        Resque.enqueue(
          MetroEnrollmentWorker,
          rows,
          params['enrollment-term-id'],
          session['user_email']
        )
      rescue CSV::MalformedCSVError => e
        flash[:danger] = "Invalid CSV - #{e.message}"
      end
    end

    redirect mount_point
  end
end
