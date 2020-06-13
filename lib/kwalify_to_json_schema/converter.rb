module KwalifyToJsonSchema

  # Heart of conversion implementation
  #
  # Example of use:
  #
  # kwalify_schema = YAML.load(File.read("kwalify_schema.yaml"))
  #
  # converter = KwalifyToJsonSchema::Converter.new(options)
  # json_schema = converter.exec(kwalify_schema)
  #
  # File.write("json_schema.json", JSON.pretty_generate(json_schema))
  class Converter
    SCHEMA = "http://json-schema.org/draft-07/schema#"

    # The options given used to initialized the converter
    attr_reader :options
    # Give the list of issues encontered while converting as array of strings.
    attr_reader :issues

    def initialize(options_hash = {})
      @options = Options.new(options_hash)
      @issues = []
    end

    # Execute the conversion process
    # @param kwalify_schema Kwalify schema to be converted as Hash
    # @return JSON schema as Hash
    def exec(kwalify_schema)
      kwalify_schema = preprocess(kwalify_schema.dup)

      json_schema = process(root, kwalify_schema)
      if issues.any? && options.issues_to_description?
        description = json_schema["description"] ||= ""
        description << "Issues when converting from Kwalify:\n"
        description << issues.map { |issue| "* #{issue}" }.join("\n")
      end

      postprocess(json_schema)
    end

    private

    def root
      {
        "$schema" => SCHEMA,
        "$id" => options.id,
        "title" => options.title,
        "description" => options.description,
      }.reject { |k, v| v.nil? }
    end

    # @param target Json schema target
    # @param kelem Kwalify element
    def process(target, kelem)

      # Add description if available
      target["description"] = kelem["desc"] if kelem["desc"]

      case ktype = kelem["type"]
      when "map"
        target["type"] = "object"
        target["additionalProperties"] = false
        mapping = kelem["mapping"]
        required = []
        if mapping.is_a? Hash
          properties = target["properties"] = {}
          mapping.each_pair { |name, e|
            process(properties[name] = {}, e)
            required << name if e["required"] == true
          }
          target["required"] = required unless required.empty?
        end
      when "seq"
        target["type"] = "array"
        sequence = kelem["sequence"]
        if sequence.is_a? Array
          process(target["items"] = {}, sequence.first)
        end
      when "str"
        target["type"] = "string"
      when "int"
        target["type"] = "integer"
      when "float", "number"
        target["type"] = "number"
      when "text"
        # Use one of
        target["oneOf"] = [
          { "type" => "string" },
          { "type" => "number" },
        ]
      when "bool"
        target["type"] = "boolean"
      when "date"
        # TODO
        new_issue Limitations::DATE_TYPE_NOT_IMPLEMENTED
      when "time"
        # TODO
        new_issue Limitations::TIME_TYPE_NOT_IMPLEMENTED
      when "timestamp"
        # TODO
        new_issue Limitations::TIMESTAMP_TYPE_NOT_IMPLEMENTED
      when "scalar"
        # Use one of
        target["oneOf"] = [
          { "type" => "string" },
          { "type" => "number" },
          { "type" => "integer" },
          { "type" => "boolean" },
        ]
      when "any"
        # Don't put type
      else
        new_issue("Unknown Kwalify type #{ktype}")
      end

      target["enum"] = kelem["enum"] if kelem["enum"]
      if range = kelem["range"]
        target["minimum"] = range["min"] if range["min"]
        target["maximum"] = range["max"] if range["max"]
        if range["min-ex"]
          target["minimum"] = range["min-ex"]
          target["exclusiveMinimum"] = true
        end
        if range["max-ex"]
          target["maximum"] = range["max-ex"]
          target["exclusiveMaximum"] = true
        end
      end
      if pa = kelem["pattern"]
        # Remove leading and trailing slash
        target["pattern"] = pa.sub(/^\//, "").sub(/\/$/, "")
      end

      if length = kelem["length"]
        case ktype
        when "str", "text"
          target["minLength"] = length["min"] if length["min"]
          target["maxLength"] = length["max"] if length["max"]
          target["minLength"] = length["min-ex"] + 1 if length["min-ex"]
          target["maxLength"] = length["max-ex"] + -1 if length["max-ex"]
        end
      end

      new_issue "'unique' is not supported by JSON Schema" if kelem["unique"]

      target
    end

    def preprocess(kwalify_schema)
      ep = options.custom_processing
      return kwalify_schema unless ep.respond_to? :preprocess
      kwalify_schema = ep.preprocess(kwalify_schema.dup)
    end

    def postprocess(json_schema)
      ep = options.custom_processing
      return json_schema unless ep.respond_to? :postprocess
      ep.postprocess(json_schema)
    end

    def new_issue(description)
      @issues << description
    end
  end


end
