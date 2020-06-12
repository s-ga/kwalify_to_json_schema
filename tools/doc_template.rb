require "erb"

module DocTemplate
  def self.render(template_file, dest_file)
    template = ERB.new(File.read(template_file))
    File.write(dest_file, template.result)
  end
end
