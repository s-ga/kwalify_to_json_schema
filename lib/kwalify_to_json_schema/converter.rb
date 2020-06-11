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
      case ktype = kelem["type"]
      when "map"
        target["type"] = "object"
        target["additionalProperties"] = false
        mapping = kelem["mapping"]
        if mapping.is_a? Hash
          properties = target["properties"] = {}
          mapping.each_pair { |name, e|
            process(properties[name] = {}, e)
          }
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
      when "bool"
        target["type"] = "boolean"
      when "date"
        # TODO
      when "time"
        # TODO
      when "timestamp"
        # TODO
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
      target["pattern"] = kelem["pattern"] if kelem["pattern"]

      # Add description if available
      target["description"] = kelem["desc"] if kelem["desc"]

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
