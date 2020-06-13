module KwalifyToJsonSchema

  # Convert a Kwalify schema file to JSON .schema.
  # The destination file can be JSON or YAML.
  # The file extension is used to select the format: .json or .yaml.
  # Other extension will fallback to JSON.
  # @peram source Path to Kwalify YAML schema
  # @param dest Path to resulting JSON schema
  def self.convert_file(source, dest, options = {})
    # Get a converter
    converter = Converter.new(options)
    # Convert
    converted = converter.exec(Serialization.deserialize_from_file(source))
    # Serialize
    Serialization.serialize_to_file(dest, converted)
  end
end
