require "minitest/autorun"
require "json-schema"
require_relative "../lib/kwalify_to_json_schema"

module KwalifyToJsonSchema
  class Test < Minitest::Test
    @@tmpdir = Dir.mktmpdir
    @@debug = false

    # Create a test method for every Kwalify schema
    Dir.glob(File.join(__dir__, "schemas", "kwalify", "*.yaml")).each { |source|
      test_name_base = File.basename(source, File.extname(source))

      # Define a method for the test JSON output
      define_method("test_#{test_name_base}_json_output".to_sym) {
        ser = KwalifyToJsonSchema::Serialization::Json
        output_file = test_name_base + ".json"
        dest = File.join(@@tmpdir, output_file)
        expected = File.join(File.join(__dir__, "schemas", "json_schema", "json", output_file))

        skip "Expected JSON result does not exist for test #{test_name_base}. The #{expected} file is missing" unless File.exist?(expected)

        # Convert
        KwalifyToJsonSchema.convert_file(source, dest)

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

      # Define a method for the test YAML output
      define_method("test_#{test_name_base}_yaml_output".to_sym) {
        ser = KwalifyToJsonSchema::Serialization::Yaml
        output_file = test_name_base + ".yaml"
        dest = File.join(@@tmpdir, output_file)
        expected = File.join(File.join(__dir__, "schemas", "json_schema", "yaml", output_file))

        skip "Expected YAML result does not exist for test #{test_name_base}. The #{expected} file is missing" unless File.exist?(expected)

        # Convert
        KwalifyToJsonSchema.convert_file(source, dest)
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
