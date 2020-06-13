module KwalifyToJsonSchema
  class Cli < Thor
    ###############################################################################################################
    CUSTOM_PROCESSING_CODE_DOC = <<~CODE
      class CustomProcessing
          # The method will be called before conversion allowing to customize the input Kwalify schema.
          # The implementation have to return the modified schema.
          # The default implemention don't modify the schema.
          # @param kwalify_schema {Hash}
          # @return modified schema
          def preprocess(kwalify_schema)
            # TODO return modified schema
          end
          
          # The method will be called after the conversion allowing to customize the output JSON schema.
          # The implementation have to return the modified schema.
          # The default implemention don't modify the schema.
          # @param json_schema {Hash}
          # @return modified schema
          def postprocess(json_schema)
            # TODO return modified schema
          end
      end
    CODE

    desc "convert KWALIFY_SCHEMA_FILE, RESULT_FILE",
         "Convert a Kwalify schema file to a JSON schema file. The result file extension will decide the format: .json or .yaml"
    option :issues_to_description,
           :type => :boolean,
           :default => false,
           :desc => "Will append any conversion issue to the schema description"
    option :custom_processing,
           :type => :string,
           :desc => <<~DESC
             Allows to provide a pre/post processing file on handled schemas.
             The given Ruby file have to provide the following class:
             #{CodeRay.scan(CUSTOM_PROCESSING_CODE_DOC, :ruby).encode :terminal}
           DESC

    def convert(kwalify_schema_file, result_file)
      opts = {
        Options::ISSUES_TO_DESCRIPTION => options[:issues_to_description],
        Options::CUSTOM_PROCESSING => custom_processing(options),
      }
      KwalifyToJsonSchema.convert_file(kwalify_schema_file, result_file, opts)
    end

    ###############################################################################################################

    desc "convert_dir KWALIFY_SCHEMA_DIR, RESULT_DIR",
         "Convert all the Kwalify schema from a directory to a JSON schema"
    option :issues_to_description,
           :type => :boolean,
           :default => false,
           :desc => "Will append any conversion issue to the schema description"
    option :format,
           :type => :string,
           :enum => ["json", "yaml"],
           :default => "json",
           :desc => "Select the output file format"
    option :recursive,
           :type => :boolean,
           :default => false,
           :desc => "Process files recursively",
           :long_desc => ""
    option :custom_processing,
           :type => :string,
           :desc => <<~DESC
             Allows to provide a pre/post processing file on handled schemas.
             The given Ruby file have to provide the following class:
             #{CodeRay.scan(CUSTOM_PROCESSING_CODE_DOC, :ruby).encode :terminal}
           DESC

    def convert_dir(kwalify_schema_dir, result_dir)
      opts = {
        Options::ISSUES_TO_DESCRIPTION => options[:issues_to_description],
        Options::CUSTOM_PROCESSING => custom_processing(options),
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

    private

    def custom_processing(options)
      pf = options[:custom_processing]
      custom_processing = nil
      if pf
        require File.expand_path(pf)
        begin
          processing_class = Object.const_get :CustomProcessing
          custom_processing = processing_class.new
        rescue NameError => e
          raise "The 'CustomProcessing' module must be defined in #{pf}"
        end
      end
      custom_processing
    end
  end
end
