module KwalifyToJsonSchema
  class Converter
    SCHEMA = "http://json-schema.org/draft-07/schema#"

    attr_reader :options

    def initialize(options = {})
      @options = options
      @issues = []
    end

    def exec(kwalify_schema)
      process(root, kwalify_schema)
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

    # Types:
    # str
    # int
    # float
    # number (== int or float)
    # text (== str or number)
    # bool
    # date
    # time
    # timestamp
    # seq
    # map
    # scalar (all but seq and map)
    # any (means any data)

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
        new_issue "'date' type is not supported by JSON Schema" if kelem["unique"]
      when "time"
        # TODO
        new_issue "'time' type is not supported by JSON Schema" if kelem["unique"]
      when "timestamp"
        # TODO
        new_issue "'timestamp' type is not supported by JSON Schema" if kelem["unique"]
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
        target["exclusiveMinimum"] = range["min-ex"] if range["min-ex"]
        target["exclusiveMaximum"] = range["max-ex"] if range["max-ex"]
      end
      if pa = kelem["pattern"]
        # Remove leading and trailing slash
        target["pattern"] = pa.sub(/^\//, "").sub(/\/$/, "")
      end

      # TODO implement 'length'
      new_issue "'length' is not implemented" if kelem["length"]
      new_issue "'unique' is not supported by JSON Schema" if kelem["unique"]

      target
    end

    def new_issue(description)
      @issues << description
    end

    def id; options[:id] end
    def title; options[:title] end
    def description; options[:description] end
  end
end
