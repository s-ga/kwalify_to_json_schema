module KwalifyToJsonSchema

  # Abstract JSON/YAML serialization/deserialization
  module Serialization
    def self.deserialize_from_file(file)
      serialization_for_file(file).deserialize(File.read(file))
    end

    def self.serialize_to_file(file, object)
      File.write(file, serialization_for_file(file).serialize(object))
    end

    def self.deserialize_from_string(string, format = "yaml")
      serialization_for_format(format).deserialize(string)
    end

    def self.serialize_to_string(object, format = "json")
      serialization_for_format(format).serialize(object)
    end

    # @return a Hash giving serialization/deserialization module and methods for a given file extension (.json/.yaml)
    def self.serialization_for_file(file)
      serialization_for_format(File.extname(file)[1..-1])
    end

    # @return a Hash giving serialization/deserialization module and methods for a format (json/yaml)
    def self.serialization_for_format(format)
      { "json" => Json, "yaml" => Yaml }[format] || Json
    end

    class Language
      def self.normalize(string); serialize(deserialize(string)); end
    end

    class Json < Language
      def self.serialize(object); JSON.pretty_generate(object); end
      def self.deserialize(string); JSON.parse(string); end
    end

    class Yaml < Language
      def self.serialize(object); YAML.dump(object); end
      def self.deserialize(string); YAML.load(string); end
    end
  end
end
