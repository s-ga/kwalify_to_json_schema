require "minitest/autorun"
require_relative "../lib/kwalify_to_json_schema"

module KwalifyToJsonSchema
  class Test < Minitest::Test
    @@tmpdir = Dir.mktmpdir
    @@debug = false

    # Create a test method for every Kwalify schema
    Dir.glob(File.join(__dir__, "schemas", "kwalify", "*.yaml")).each { |source|
      test_name = File.basename(source, File.extname(source))
      json_file = test_name + ".json"
      dest = File.join(@@tmpdir, json_file)
      expected_file = File.join(File.join(__dir__, "schemas", "json", json_file))
      raise "Expected result does not exist for test #{test_name}. The #{expected_file} file is missing" unless File.exist?(expected_file)

      # Define a method for the test
      define_method("test_#{test_name}".to_sym) {
        # Convert
        KwalifyToJsonSchema.convert_file(source, dest)

        if @@debug
          puts test_name
          puts Test::normalize_json(File.read(dest))
        end
        # Compare to expected result
        assert_equal(
          Test::normalize_json(File.read(expected_file)),
          Test::normalize_json(File.read(dest))
        )
      }
    }

    def self.normalize_json(json)
      JSON.pretty_generate(JSON.parse(json))
    end
  end
end
