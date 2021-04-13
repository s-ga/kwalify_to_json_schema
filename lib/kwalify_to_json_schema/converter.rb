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
    SCHEMA = "http://json-schema.org/%s/schema#"

    # The options given used to initialized the converter
    attr_reader :options
    # Give the list of issues encontered while converting as array of strings.
    attr_reader :issues

    # Converter options:
    # | Name                  | Type   | Default value| Description                                                                              |
    # |-----------------------|--------|--------------|------------------------------------------------------------------------------------------|
    # | :id                   | string | nil          | The JSON schema identifier                                                               |
    # | :title                | string | nil          | The JSON schema title                                                                    |
    # | :description          | string | nil          | The JSON schema description. If not given the Kwalify description will be used if present|
    # | :issues_to_description| boolean| false        | To append the issues to the JSON schema description                                      |
    # | :issues_to_stderr     | boolean| false        | To write the issues to standard error output                                             |
    # | :custom_processing    | object | nil          | To customize the conversion                                                              |
    # | :schema_version       | string | "draft-04"   | JSON schema version. Changing this value only change the value of $schema field          |
    # | :verbose              | boolean| false        | To be verbose when converting                                                            |
    # --
    # @param options {Options} or {Hash}
    def initialize(options = {})
      @options = Options.new(options)
      @issues = Issues.new
    end

    # Execute the conversion process
    # @param kwalify_schema Kwalify schema as Hash or YAML string to be converted as Hash
    # @return JSON schema as Hash
    def exec(kwalify_schema)
      kwalify_schema = YAML.load(kwalify_schema) if kwalify_schema.is_a? String
      kwalify_schema = preprocess(kwalify_schema.dup)

      json_schema = process(root, kwalify_schema)
      if issues.any? && options.issues_to_description?
        description = json_schema["description"] ||= ""
        description << "Issues when converting from Kwalify:\n"
        description << issues.descriptions_uniq.map { |description| "* #{description}" }.join("\n")
      end

      # Override description if given in option
      json_schema["description"] = options.description if options.description
      STDERR.puts issues if options.issues_to_stderr?

      postprocess(json_schema)
    end

    private

    def root
      {
        "$schema" => SCHEMA % options.schema_version,
        "id" => options.id,
        "title" => options.title,
      }.reject { |k, v| v.nil? }
    end

    # @param target Json schema target
    # @param kelem Kwalify element
    def process(target, kelem, path = [])

      # Add description if available
      target["description"] = kelem["desc"] if kelem["desc"]
      ktype = kelem["type"]
      path += [ktype] if ktype

      case ktype
      when "map"
        target["type"] = "object"
        target["additionalProperties"] = false
        mapping = kelem["mapping"]
        required = []
        if mapping.is_a? Hash
          properties = target["properties"] = {}
          mapping.each_pair { |name, e|
            # Ignore mapping default value
            if name == "="
              process(target["additionalProperties"] = {}, e, path)
            else
              process(properties[name] = {}, e, path + [name])
              required << name if e["required"] == true
            end
          }
          target["required"] = required unless required.empty?
        end
      when "seq"
        target["type"] = "array"
        sequence = kelem["sequence"]
        if sequence.is_a? Array
          rule = sequence.first
          if rule["unique"]
            target["uniqueItems"] = true
            rule = rule.dup
            rule.delete("unique")
          end
          process(target["items"] = {}, rule)
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
        new_issue path, Limitations::DATE_TYPE_NOT_IMPLEMENTED
      when "time"
        # TODO
        new_issue path, Limitations::TIME_TYPE_NOT_IMPLEMENTED
      when "timestamp"
        # TODO
        new_issue path, Limitations::TIMESTAMP_TYPE_NOT_IMPLEMENTED
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

      new_issue path, Limitations::UNIQUE_NOT_SUPPORTED if kelem["unique"]

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

    def new_issue(path, description)
      @issues << Issue.new(path, description)
    end
  end
end
