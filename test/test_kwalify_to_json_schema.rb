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

      %w(json yaml).map { |expected_type|

        # Define a method for the test JSON output
        define_method("test_#{test_name_base}_#{expected_type}_output".to_sym) {
          output_file = test_name_base + ".#{expected_type}"
          expected = File.join(File.join(__dir__, "schemas", "json_schema", expected_type, output_file))

          skip "Expected #{expected_type.upcase} result does not exist for test #{test_name_base}. The #{expected} file is missing" unless File.exist?(expected)

          ser = KwalifyToJsonSchema::Serialization::serialization_for_type(expected_type)
          dest = File.join(@@tmpdir, output_file)

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
