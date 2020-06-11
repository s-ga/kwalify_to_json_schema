module KwalifyToJsonSchema

  # Convert a Kwalify schema file to JSON .schema.
  # The destination file can be JSON or YAML.
  # The file extension is used to select the format: .json or .yaml.
  # Other extension will fallback to JSON.
  # @peram source Path to Kwalify YAML schema
  # @param dest Path to resulting JSON schema
  def self.convert_file(source, dest, options = {})
    # Select a serializer: JSON or YAML
    json_serializer = { mod: JSON, method: :pretty_generate }
    serializer = {
      ".json" => json_serializer,
      ".yaml" => { mod: YAML, method: :dump },
    }[File.extname(dest)] || json_serializer

    # Convert
    converted = convert_object(YAML.load(File.read(source)), options)

    # Serialize
    File.write(dest, serializer[:mod].send(serializer[:method], converted))
  end

  def self.convert_object(kwalify_schema, options = {})
    Converter.new(options).exec(kwalify_schema)
  end
end
