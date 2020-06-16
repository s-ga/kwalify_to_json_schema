require_relative "../tools/all"
desc "build all (build+test+doc)"
task :buildall => [:'code:options:update', :test, :'doc:update', :build]
