require_relative "../tools/all"
namespace :code do
  namespace :options do
    desc "Update options in code comments"
    task :update do
      Dir.glob(File.join(__dir__, "..", "lib", "**", "*.rb")) { |file|
        Options.inject_as_code_comment(file)
      }
    end
  end
end
