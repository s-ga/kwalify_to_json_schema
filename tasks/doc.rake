require_relative "../tools/all"
namespace :doc do
  desc "Update documentation"
  task :update do
    Dir.chdir(File.join(__dir__, "..")) {
      DocTemplate.render("doc_template/README.md.erb", "README.md")
    }
  end
end
