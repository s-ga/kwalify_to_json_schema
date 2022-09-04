require "minitest/autorun"
require "json-schema"
require_relative "../lib/kwalify_to_json_schema"

module KwalifyToJsonSchema
  class Test < Minitest::Test
    @@debug = false
    @@tmpdir = Dir.mktmpdir

    custom_version = "draft-07"

    [
      { test_group: "conversion", cli_options: [] },
      { test_group: "custom_processing", cli_options: ["--custom-processing", File.join(__dir__, "custom_processing.rb")] },
    ].each { |entry|
      test_group = entry[:test_group]
      cli_options = entry[:cli_options]

      # Create a test method for every Kwalify schema
      Dir.glob(File.join(__dir__, test_group, "kwalify", "*.{yaml,yml}")).each { |source|
        test_file_base = File.basename(source, File.extname(source))
        test_name_base = test_file_base.gsub("#", "_")
        expected_formats = %w(json yaml)

        # Define a method for the test JSON output
        define_method("test_#{test_group}_#{test_name_base}_output".to_sym) {
          formats_done = 0
          expected_formats.map { |expected_format|
            output_file = test_file_base + ".#{expected_format}"
            expected = File.join(File.join(__dir__, test_group, "json_schema", expected_format, output_file))

            next unless File.exist?(expected)
            formats_done += 1

            ser = KwalifyToJsonSchema::Serialization::serialization_for_format(expected_format)
            dest = File.join(@@tmpdir, output_file)

            args = ["convert", source, dest]
            args.concat ["--id", test_file_base]
            args.concat ["--title", "Conversion of #{test_file_base}"]
            # Add issues to description if filename include "#issues_to_description"
            args << "--issues_to_description" if output_file.include?("#issues_to_description")
            # Add schema_version include "#schema_version"
            if output_file.include?("##{custom_version}")
              args.concat(["--schema_version", custom_version])
            end
            args.concat cli_options

            # Convert
            # KwalifyToJsonSchema.convert_file(source, dest, options)
            KwalifyToJsonSchema::Cli.start(args)

            # Validate schema
            validate_json_schema_file(dest)

            if @@debug
              puts test_name_base
              puts ser.normalize(File.read(dest))
            end
            # Compare to expected result
            assert_equal(
              ser.normalize(File.read(expected)),
              ser.normalize(File.read(dest))
            )
          }

          raise "None of the expected #{expected_formats.join(", ")} result for test #{test_name_base} was found" if formats_done == 0
        }
      }
    }

    def validate_json_schema_file(schema_file)
      schema = KwalifyToJsonSchema::Serialization::deserialize_from_file(schema_file)
      validate_json_schema(schema)
    end

    def validate_json_schema(schema)
      # FIXME draft7 is not available in current json-schema gem
      metaschema = JSON::Validator.validator_for_name("draft4").metaschema
      JSON::Validator.validate!(metaschema, schema)
    end
  end
end
