require 'bundler/setup'
require 'wolf_core'
require 'csv'
require_relative './metro_enrollment_worker'
require_relative './validation_helper'

class MetroEnrollmentApp < WolfCore::App
  set :title, 'MSU/CU Enrollment'
  set :root, File.dirname(__FILE__)
  set :logger, create_logger
  set :auth_paths, [/.*/]

  enable :exclude_js
  enable :exclude_css

  helpers ValidationHelper

  get '/' do
    slim :index
  end

  post '/' do
    errors = form_validation_errors(params, session)
    if errors.any?
      flash[:danger] = errors.join("\n")
    else
      Resque.enqueue(
        MetroEnrollmentWorker,
        CSV.read(params['enrollment-data-file'][:tempfile]),
        params['enrollment-term-id'],
        session['user_email']
      )
    end

    redirect mount_point
  end
end
