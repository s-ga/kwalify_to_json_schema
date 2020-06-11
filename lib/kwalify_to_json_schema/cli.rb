module KwalifyToJsonSchema
  class Cli < Thor
    package_name "kwalify_to_json_schema"
    map "-L" => :list

    desc "convert KWALIFY_SCHEMA_FILE, RESULT_FILE", "Convert a Kwalify schema file to a JSON schema file. The result file extension will decide the format: .json or .yaml"
    # method_options :format => :string, :enum => ["json", "yaml"], :default => "json"

    def convert(kwalify_schema_file, result_file)
      KwalifyToJsonSchema.convert_file(kwalify_schema_file, result_file)
    end

    def self.exit_on_failure?
      false
    end
  end

  Cli.start
end
