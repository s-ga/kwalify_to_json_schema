module KwalifyToJsonSchema
  def self.convert_file(source, dest, options = {})
    File.write(
      dest,
      JSON.pretty_generate(
        convert_object(
          YAML.load(File.read(source)), options
        )
      )
    )
  end

  def self.convert_object(kwalify_schema, options = {})
    Converter.new(options).exec(kwalify_schema)
  end
end
