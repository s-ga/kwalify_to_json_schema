module KwalifyToJsonSchema
  # The possible options for the conversion and the associated accessors
  class Options
    # Available options
    DECLARATION = %q(
    ID                    # The JSON schema identifier [String] (nil)
    TITLE                 # The JSON schema title [String] (nil)
    DESCRIPTION           # The JSON schema description [String] (nil)
    ISSUES_TO_DESCRIPTION # To append the issuses to the JSON schema description [Boolean] (false)
    CUSTOM_PROCESSING     # To customize the conversion [Object] (nil)
    )

    # The options as Hash
    attr_reader :options_hash

    def initialize(options_hash)
      @options_hash = options_hash
    end

    # Parse options declaration text and give an array of Hash
    def self.parse
      DECLARATION.lines.map { |l|
        next nil if l.strip.empty?

        # Parse line
        const_name, comment = l.split("#", 2).map(&:strip)
        name = const_name.downcase.to_s
        description = comment.split("[").first.strip
        # Get type and default value
        m = comment.match(/\[(.+)\].*\((.+)\)/)
        type, default_value = m.captures
        default_value = eval(default_value)

        # Create read accessor
        attr_reader_name = "#{name}#{type == "Boolean" ? "?" : ""}"

        # Array entry as Hash for the option
        {
          const_name: const_name,
          const_name_full: "#{Options.name}::#{const_name}",
          name: name,
          description: description,
          type: type,
          default_value: default_value,
          attr_reader_name: attr_reader_name,
        }
      }.compact
    end

    # Setup the constants and methods for the options
    # Example: ID will lead to get ID constant and :id method
    def self.setup
      parse.each { |o|
        # Create constant
        const_set o[:const_name], o[:name]

        # Create read accessor
        define_method(o[:attr_reader_name]) {
          options_hash[o[:name]] || o[:default_value]
        }
      }
    end

    setup
  end
end
