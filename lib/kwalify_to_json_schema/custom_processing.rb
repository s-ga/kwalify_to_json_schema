module KwalifyToJsonSchema
  # Template class for custom processing
  class CustomProcessing
    # The method will be called before conversion allowing to customize the input Kwalify schema.
    # The implementation have to return the modified schema.
    # The default implemention don't modify the schema.
    def preproces(kwalify_schema); kwalify_schema; end

    # The method will be called after the conversion allowing to customize the output JSON schema.
    # The implementation have to return the modified schema.
    # The default implemention don't modify the schema.
    def postprocess(json_schema); json_schema; end
  end
end
