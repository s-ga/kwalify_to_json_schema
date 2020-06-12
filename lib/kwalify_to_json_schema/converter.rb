module KwalifyToJsonSchema
  class Converter
    SCHEMA = "http://json-schema.org/draft-07/schema#"

    module Limitations
      DATE_TYPE_NOT_IMPLEMENTED = "Kwalify 'date' type is not supported and will be ignored"
      TIME_TYPE_NOT_IMPLEMENTED = "Kwalify 'time' type is not supported and will be ignored"
      TIMESTAMP_TYPE_NOT_IMPLEMENTED = "Kwalify 'timestamp' type is not supported and will be ignored"
    end

    attr_reader :options
    attr_reader :issues

    def initialize(options = {})
      @options = options
      @issues = []
    end

    def exec(kwalify_schema)
      kwalify_schema = preprocess(kwalify_schema.dup)

      json_schema = process(root, kwalify_schema)
      if issues.any? && issues_to_description?
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
        "$id" => id,
        "title" => title,
        "description" => description,
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
        new_issue DATE_TYPE_NOT_IMPLEMENTED
      when "time"
        # TODO
        new_issue TIME_TYPE_NOT_IMPLEMENTED
      when "timestamp"
        # TODO
        new_issue TIMESTAMP_TYPE_NOT_IMPLEMENTED
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
      ep = custom_processing
      return kwalify_schema unless ep.respond_to? :preprocess
      kwalify_schema = ep.preprocess(kwalify_schema.dup)
    end

    def postprocess(json_schema)
      ep = custom_processing
      return json_schema unless ep.respond_to? :postprocess
      ep.postprocess(json_schema)
    end

    def new_issue(description)
      @issues << description
    end

    def id; options[:id] end
    def title; options[:title] end
    def description; options[:description] end
    def issues_to_description?; options[:issues_to_description] == true end

    # Give an external procressing object given by options
    # See {CustomProcessing}.
    # @return a processing object, a default one if none was specified in options.
    def custom_processing
      options[:custom_processing] || CustomProcessing.new
    end
  end

  #
  class CustomProcessing
    # The method will be called before conversion allowing to customize the input Kwalify schema.
    # The implementation have to return the modified schema.
    # The default implemention don't modify the schema.
    def preproces(kwalify_schema); kwalify_schema; end

    # The method will be called after the conversion allowing to customize the output JSON schema.
    # The implementation have to return the modified schema.
    # The default implemention don't modify the schema.
    def postprocess(json_schema); json_schema; end
  end
end
