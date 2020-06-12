begin
  require 'rake/testtask'
  Rake::TestTask.new :test do |t|
    t.libs << 'test'
    t.pattern = 'test/**/test_*.rb'
    t.verbose = true
    t.warning = true
  end
rescue LoadError
  warn $!.message
end

namespace :test do
  desc 'Run unit and feature tests'
  task all: [:test, :features]
end
