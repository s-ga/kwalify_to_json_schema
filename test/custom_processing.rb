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
