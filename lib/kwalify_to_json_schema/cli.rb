module KwalifyToJsonSchema
  class Cli < Thor
    package_name "kwalify_to_json_schema"

    desc "convert KWALIFY_SCHEMA_FILE, RESULT_FILE", "Convert a Kwalify schema file to a JSON schema file. The result file extension will decide the format: .json or .yaml"
    option :issues_to_description, :type => :boolean, :default => false, :desc => "Will append any conversion issue to the schema description"

    def convert(kwalify_schema_file, result_file)
      opts = {
        issues_to_description: options[:issues_to_description],
      }
      KwalifyToJsonSchema.convert_file(kwalify_schema_file, result_file, opts)
    end

    desc "convert_dir KWALIFY_SCHEMA_DIR, RESULT_DIR", "Convert all the Kwalify schema from a directory to a JSON schema"
    option :issues_to_description, :type => :boolean, :default => false, :desc => "Will append any conversion issue to the schema description"
    option :format, :type => :string, :enum => ["json", "yaml"], :default => "json", :desc => "Select the output file format"
    option :recursive, :type => :boolean, :default => false, :desc => "Process files recursively"

    def convert_dir(kwalify_schema_dir, result_dir)
      opts = {
        issues_to_description: options[:issues_to_description],
      }

      path = [kwalify_schema_dir, options["recursive"] ? "**" : nil, "*.yaml"].compact
      Dir.glob(File.join(*path)).each { |kwalify_schema_file|
        result_file = File.join(result_dir, File.basename(kwalify_schema_file, File.extname(kwalify_schema_file))) + ".#{options["format"]}"
        KwalifyToJsonSchema.convert_file(kwalify_schema_file, result_file, opts)
      }
    end

    def self.exit_on_failure?
      false
    end
  end
end
