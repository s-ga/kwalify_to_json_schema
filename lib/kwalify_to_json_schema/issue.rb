module KwalifyToJsonSchema
  # Used to represent issues encoutered while converting
  class Issue
    attr_reader :path
    attr_reader :description

    def initialize(path, description)
      @path = path
      @description = description
    end

    def to_s
      "Issue #{path.join "/"}: #{description}"
    end
  end
end
