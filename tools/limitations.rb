require_relative "../lib/kwalify_to_json_schema/converter"

# Gives implementation limitations
module Limitations

  # @return list of limitation as array of strings
  def self.list
    KwalifyToJsonSchema::Converter::Limitations.constants.map { |cst|
      KwalifyToJsonSchema::Converter::Limitations.const_get(cst)
    }
  end

  # @return limitation as markdown text
  def self.markdown
    list.map { |l|
      "* #{l}"
    }.join("\n")
  end
end
