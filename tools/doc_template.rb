require "erb"

module DocTemplate
  def self.render(template_file, dest_file)
    template = ERB.new(File.read(template_file), nil, "-")
    File.write(dest_file, template.result(get_binding(template_file)))
  end

  def self.get_binding(template_file)
    template_dir = File.dirname template_file
    binding
  end
end
