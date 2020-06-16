module KwalifyToJsonSchema
  # The possible options for the conversion and the associated accessors
  class Options
    # Converter options:
    # | Name                  | Type   | Default value| Description                                                                              |
    # |-----------------------|--------|--------------|------------------------------------------------------------------------------------------|
    # | :id                   | string | nil          | The JSON schema identifier                                                               |
    # | :title                | string | nil          | The JSON schema title                                                                    |
    # | :description          | string | nil          | The JSON schema description. If not given the Kwalify description will be used if present|
    # | :issues_to_description| boolean| false        | To append the issuses to the JSON schema description                                     |
    # | :issues_to_stderr     | boolean| false        | To write the issuses standard error output                                               |
    # | :custom_processing    | object | nil          | To customize the conversion                                                              |
    # | :schema_version       | string | "draft-04"   | JSON schema version. Changing this value only change the value of $schema field          |
    # | :verbose              | boolean| false        | To be verbose when converting                                                            |
    # --
    DECLARATION = %q(
    ID                    # The JSON schema identifier [string] (nil)
    TITLE                 # The JSON schema title [string] (nil)
    DESCRIPTION           # The JSON schema description. If not given the Kwalify description will be used if present [string] (nil)
    ISSUES_TO_DESCRIPTION # To append the issuses to the JSON schema description [boolean] (false)
    ISSUES_TO_STDERR      # To write the issuses standard error output [boolean] (false)
    CUSTOM_PROCESSING     # To customize the conversion [object] (nil)
    SCHEMA_VERSION        # JSON schema version. Changing this value only change the value of $schema field[string] ("draft-04")
    VERBOSE               # To be verbose when converting [boolean] (false)
    )

    # The options as Hash
    attr_reader :options_hash

    def initialize(options)
      @options_hash = options.is_a?(Options) ? options.options_hash : options
    end

    def to_s
      YAML.dump("Options" => options_hash)
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
        attr_reader_name = "#{name}#{type == "boolean" ? "?" : ""}"

        # Array entry as Hash for the option
        {
          const_name: const_name,
          const_name_full: "#{Options.name}::#{const_name}",
          name: name.to_sym,
          description: description,
          type: type,
          default_value: default_value,
          attr_reader_name: attr_reader_name,
        }
      }.compact
    end

    # Same as :parse but give a Hash with the name as key
    def self.parse_hash
      parse.map { |e| [e[:name], e] }.to_h
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

    # Get description for option name
    def self.cli_option(name)
      o = parse_hash[name]
      [o[:name], :type => o[:type].to_sym, :default => o[:default_value], :desc => o[:description]]
    end

    setup
  end
end
