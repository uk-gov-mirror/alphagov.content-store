require 'whenever'

# default cron env is "/usr/bin:/bin" which is not sufficient as govuk_setenv is in /usr/local/bin
env :PATH, '/usr/local/bin:/usr/bin:/bin'

set :output, error: 'log/cron.error.log', standard: 'log/cron.log'
job_type :rake, "cd :path && govuk_setenv content-store bundle exec rake :task :output"

every 1.day, at: "2:15 am" do
  rake "publishing_delay_report:report_delays"
end
