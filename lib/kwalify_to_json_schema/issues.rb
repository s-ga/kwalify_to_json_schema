module KwalifyToJsonSchema
  # Used to hold issues encoutered while converting
  class Issues < Array

    # Get an array with only one instance of each description
    def descriptions_uniq
      map(&:description).uniq
    end
  end
end
