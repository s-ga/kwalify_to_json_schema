require "minitest/autorun"
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
        json_output_file = test_name_base + ".json"
        json_dest = File.join(@@tmpdir, json_output_file)
        json_expected = File.join(File.join(__dir__, "schemas", "json_schema", "json", json_output_file))

        skip "Expected JSON result does not exist for test #{test_name_base}. The #{json_expected} file is missing" unless File.exist?(json_expected)

        # Convert
        KwalifyToJsonSchema.convert_file(source, json_dest)

        if @@debug
          puts Test::normalize_json(File.read(json_dest))
        end
        # Compare to expected result
        assert_equal(
          Test::normalize_json(File.read(json_expected)),
          Test::normalize_json(File.read(json_dest))
        )
      }

      # Define a method for the test YAML output
      define_method("test_#{test_name_base}_yaml_output".to_sym) {
        yaml_output_file = test_name_base + ".yaml"
        yaml_dest = File.join(@@tmpdir, yaml_output_file)
        yaml_expected = File.join(File.join(__dir__, "schemas", "json_schema", "yaml", yaml_output_file))

        skip "Expected YAML result does not exist for test #{test_name_base}. The #{yaml_expected} file is missing" unless File.exist?(yaml_expected)

        # Convert
        KwalifyToJsonSchema.convert_file(source, yaml_dest)

        if @@debug
          puts test_name_base
          puts Test::normalize_yaml(File.read(yaml_dest))
        end
        # Compare to expected result
        assert_equal(
          Test::normalize_yaml(File.read(yaml_expected)),
          Test::normalize_yaml(File.read(yaml_dest))
        )
      }
    }

    def self.normalize_json(json)
      JSON.pretty_generate(JSON.parse(json))
    end

    def self.normalize_yaml(yaml)
      YAML.dump(YAML.load yaml)
    end
  end
end
