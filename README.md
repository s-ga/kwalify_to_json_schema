<!-- Do not update README.md but doc_template/README.md.erb and execute rake doc:update-->


# kwalify_to_json_schema [![Gem Version](https://badge.fury.io/rb/kwalify_to_json_schema.svg)](https://badge.fury.io/rb/kwalify_to_json_schema)
Kwalify schemas to JSON schemas conversion

This gem allows to convert [Kwalify](http://www.kuwata-lab.com/kwalify/) schemas to [JSON schema](https://json-schema.org/).

## Installation

```console
gem install kwalify_to_json_schema
``` 

## Limitations

The current implementation has the following limitations:

* Kwalify 'time' type is not supported and is ignored
* Kwalify 'timestamp' type is not supported and is ignored
* Kwalify 'unique' is not supported by JSON Schema and is ignored
* Kwalify mapping default value is not supported by JSON Schema and is ignored
* Kwalify 'date' type is not supported and is ignored

## Command line

The conversion can be done using the `kwalify_to_json_schema` command.
To get help:

```console
kwalify_to_json_schema help

Commands:
  rake convert KWALIFY_SCHEMA_FILE, RESULT_FILE    # Convert a Kwalify schema file to a JSON schema file. The result file extension will decide the format: .json or .yaml
  rake convert_dir KWALIFY_SCHEMA_DIR, RESULT_DIR  # Convert all the Kwalify schema from a directory to a JSON schema
  rake help [COMMAND]                              # Describe available commands or one specific command

```

Help for `convert` command:
```console
kwalify_to_json_schema help

Usage:
  rake convert KWALIFY_SCHEMA_FILE, RESULT_FILE

Options:
  [--id=ID]                                                # The JSON schema identifier
  [--title=TITLE]                                          # The JSON schema title
  [--description=DESCRIPTION]                              # The JSON schema description. If not given the Kwalify description will be used if present
  [--issues-to-description], [--no-issues-to-description]  # To append the issuses to the JSON schema description
  [--issues-to-stderr], [--no-issues-to-stderr]            # To write the issuses standard error output
  [--schema-version=SCHEMA_VERSION]                        # JSON schema version. Changing this value only change the value of $schema field
                                                           # Default: draft-04
  [--verbose], [--no-verbose]                              # To be verbose when converting
  [--custom-processing=CUSTOM_PROCESSING]                  # Allows to provide a pre/post processing file on handled schemas.
The given Ruby file have to provide the following class:
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


Convert a Kwalify schema file to a JSON schema file. The result file extension will decide the format: .json or .yaml
```


### Converting a single file

The destination file extension decides if the resulting JSON schema is in JSON or YAML.

Source Kwalify file used as example:
```yaml
type: map
desc: Test 'enum', 'pattern' and 'range'
mapping:
  str_enum:
    type: str
    enum:
      - A
      - B
      - C
  str_regexp:
    type: str
    pattern: /^prefix_\.*/

  number_range:
    type: number
    range:
      min: 0
      max: 9

  number_range_ex:
    type: number
    range:
      min-ex: 0
      max-ex: 9

  str_length:
    type: str
    length:
      min: 4
      max: 8
  str_length_ex:
    type: str
    length:
      min-ex: 4
      max-ex: 8
```

#### Convert to JSON format
```console
kwalify_to_json_schema convert kwalify_schema.yaml json_schema.json
```

Will produce:

```json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "description": "Test 'enum', 'pattern' and 'range'",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "str_enum": {
      "type": "string",
      "enum": [
        "A",
        "B",
        "C"
      ]
    },
    "str_regexp": {
      "type": "string",
      "pattern": "^prefix_\\.*"
    },
    "number_range": {
      "type": "number",
      "minimum": 0,
      "maximum": 9
    },
    "number_range_ex": {
      "type": "number",
      "minimum": 0,
      "exclusiveMinimum": true,
      "maximum": 9,
      "exclusiveMaximum": true
    },
    "str_length": {
      "type": "string",
      "minLength": 4,
      "maxLength": 8
    },
    "str_length_ex": {
      "type": "string",
      "minLength": 5,
      "maxLength": 7
    }
  }
}
```


#### Convert to YAML format
```console
kwalify_to_json_schema convert kwalify_schema.yaml json_schema.yaml
```

Will produce:

```yaml
---
"$schema": http://json-schema.org/draft-04/schema#
description: Test 'enum', 'pattern' and 'range'
type: object
additionalProperties: false
properties:
  str_enum:
    type: string
    enum:
    - A
    - B
    - C
  str_regexp:
    type: string
    pattern: "^prefix_\\.*"
  number_range:
    type: number
    minimum: 0
    maximum: 9
  number_range_ex:
    type: number
    minimum: 0
    exclusiveMinimum: true
    maximum: 9
    exclusiveMaximum: true
  str_length:
    type: string
    minLength: 4
    maxLength: 8
  str_length_ex:
    type: string
    minLength: 5
    maxLength: 7

```

### Converting a directory

#### Convert to JSON format

```console
kwalify_to_json_schema convert_dir source_dir dest_dir --format json
```

#### Convert to YAML format

```console
kwalify_to_json_schema convert_dir source_dir dest_dir --format yaml
```

### Custom processing

I could happen what your schema are not stored as it and may require some transformation.
It is possible to provide a custom processing class in order to pre and post process the schemas.

Example of Kwalify schemas that needs processing:
```yaml
my_custom_key:
  type: map
  desc: Test 'enum', 'pattern' and 'range'
  mapping:
    str_enum:
      type: str
```

The schema is nested under the `my_custom_key` key.
We have to remove it before processing and want to keep it after the conversion.

The following custom class will do the job:
```ruby
# Customization of Kwalify to JSON schema
class CustomProcessing
  def preprocess(kwalify_schema)
    # Remove and keep the wrapping name
    head = kwalify_schema.first
    @name = head.first
    head.last
  end

  def postprocess(json_schema)
    # Restore the wrapping name
    { @name => json_schema }
  end
end
```

Let's store it in the `name_wrapping_custom_processing.rb` file.
We can now convert using:
```console
kwalify_to_json_schema convert --custom_processing kwalify_to_json_schema.rb kwalify_schema.yaml json_schema.yaml
```

Result will be:
```yaml
my_custom_key:
  "$schema": http://json-schema.org/draft-04/schema#
  description: Test 'enum', 'pattern' and 'range'
  type: object
  additionalProperties: false
  properties:
    str_enum:
      type: string
      enum:
        - A
        - B
        - C
```

## Using the API

Conversion can also be done using directly the Ruby API.

```ruby
require 'kwalify_to_json_schema'

# Convert to JSON format
KwalifyToJsonSchema.convert_file("kwalify_schema.yaml", "json_schema.json")

# Convert to YAML format
KwalifyToJsonSchema.convert_file("kwalify_schema.yaml", "json_schema.yaml")

# Specify the identifier
KwalifyToJsonSchema.convert_file("kwalify_schema.yaml", "json_schema.json", { id: "schema/example.json" })
```

### Options

The following options are available:

| Name                    | Type     | Default value| Description                                                                                |
|-------------------------|----------|--------------|--------------------------------------------------------------------------------------------|
| `:id`                   | `string` | `nil`        | _The JSON schema identifier_                                                               |
| `:title`                | `string` | `nil`        | _The JSON schema title_                                                                    |
| `:description`          | `string` | `nil`        | _The JSON schema description. If not given the Kwalify description will be used if present_|
| `:issues_to_description`| `boolean`| `false`      | _To append the issuses to the JSON schema description_                                     |
| `:issues_to_stderr`     | `boolean`| `false`      | _To write the issuses standard error output_                                               |
| `:custom_processing`    | `object` | `nil`        | _To customize the conversion_                                                              |
| `:schema_version`       | `string` | `"draft-04"` | _JSON schema version. Changing this value only change the value of $schema field_          |
| `:verbose`              | `boolean`| `false`      | _To be verbose when converting_                                                            |
