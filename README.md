<!-- Do not update README.md but doc_template/README.md.erb and execute rake doc:update-->


# kwalify_to_json_schema
Kwalify schemas to JSON schemas conversion

This gem allows to convert [Kwalify](http://www.kuwata-lab.com/kwalify/) schemas to a JSON schemas Draft 7

## Limitations

The current implementation has the following limitations:

* Kwalify 'time' type is not supported and is ignored
* Kwalify 'timestamp' type is not supported and is ignored
* Kwalify 'date' type is not supported and is ignored

## Converting a single file

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

### Convert to JSON format
```console
kwalify_to_json_schema convert kwalify_schema.yaml json_schema.json
```

Will produce:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
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


### Convert to YAML format
```console
kwalify_to_json_schema convert kwalify_schema.yaml json_schema.yaml
```

Will produce:

```yaml
---
"$schema": http://json-schema.org/draft-07/schema#
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

## Converting a directory

### Convert to JSON format

```console
kwalify_to_json_schema convert_dir source_dir dest_dir --format json
```

### Convert to YAML format

```console
kwalify_to_json_schema convert_dir source_dir dest_dir --format yaml
```

## Custom processing

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
  "$schema": http://json-schema.org/draft-07/schema#
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

| Name                    | Type     | Default value| Description                                           |
|-------------------------|----------|--------------|-------------------------------------------------------|
| `:id`                   | `String` | `nil`        | _The JSON schema identifier_                          |
| `:title`                | `String` | `nil`        | _The JSON schema title_                               |
| `:description`          | `String` | `nil`        | _The JSON schema description_                         |
| `:issues_to_description`| `Boolean`| `false`      | _To append the issuses to the JSON schema description_|
| `:custom_processing`    | `Object` | `nil`        | _To customize the conversion_                         
