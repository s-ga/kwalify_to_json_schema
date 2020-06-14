require_relative "../tools/all"
desc "Create release"
task :release => [:'code:options:update', :test, :'doc:update', :build]
