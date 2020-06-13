module KwalifyToJsonSchema

  # Convert a Kwalify schema file to JSON .schema.
  # The destination file can be JSON or YAML.
  # The file extension is used to select the format: .json or .yaml.
  # Other extension will fallback to JSON.
  # Options:
  # | Name                  | Type   | Default value| Description                                         |
  # |-----------------------|--------|--------------|-----------------------------------------------------|
  # | :id                   | String | nil          | The JSON schema identifier                          |
  # | :title                | String | nil          | The JSON schema title                               |
  # | :description          | String | nil          | The JSON schema description                         |
  # | :issues_to_description| Boolean| false        | To append the issuses to the JSON schema description|
  # | :custom_processing    | Object | nil          | To customize the conversion                         |
  # --
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

  def self.convert_string(kwalify_schema, source_format = "yaml", dest_format = "json", options = {})
    # Get a converter
    converter = Converter.new(options)
    # Convert
    converted = converter.exec(Serialization.deserialize_from_string(kwalify_schema, source_format))
    # Serialize
    Serialization.serialize_to_string(converted, dest_format)
  end
end
