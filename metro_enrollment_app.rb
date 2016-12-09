require 'wolf_core'
require 'csv'
require_relative './metro_enrollment_worker'

class MetroEnrollmentApp < WolfCore::App
  set :title, 'MSU/CU Enrollment'
  set :root, File.dirname(__FILE__)
  set :logger, create_logger
  set :auth_paths, [/.*/]

  get '/' do
    slim :index
  end

  post '/' do
    Resque.enqueue(
      MetroEnrollmentWorker,
      CSV.read(params['enrollment-data-file'][:tempfile]),
      params['enrollment-term-id'],
      session['user_email']
    )

    redirect mount_point
  end
end
