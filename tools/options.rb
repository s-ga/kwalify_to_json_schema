require "yaml"
require_relative "../lib/kwalify_to_json_schema/options"

# Gives implementation limitations
module Options

  # @return list of limitation as array of strings
  def self.list
    KwalifyToJsonSchema::Options.parse
  end

  # @return limitation as markdown text
  def self.markdown
    header = ["Name", "Type", "Default value", "Description"]

    nb_cols = header.length

    table = [header] +
            [[""] * nb_cols] +
            list.map { |o|
              [
                "`#{o[:name].to_sym.inspect}`",
                "`#{o[:type]}`",
                "`#{o[:default_value].inspect}`",
                "_#{o[:description]}_",
              ]
            }
    nb_rows = table.length

    cols_max_length = (0..nb_cols - 1).map { |c|
      (0..nb_rows - 1).map { |r|
        cell = table[r][c]
        cell.length
      }.max
    }

    table.map.each_with_index { |row, r|
      row.map.each_with_index { |cell, c|
        max_length = cols_max_length[c]
        if r == 1
          "|-" + cell + ("-" * (max_length - cell.length))
        else
          "| " + cell + (" " * (max_length - cell.length))
        end
      }.join
    }.join "|\n"
  end
end
