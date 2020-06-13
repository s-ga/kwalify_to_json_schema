require "yaml"
require_relative "../lib/kwalify_to_json_schema/options"

# Gives implementation limitations
module Options

  # @return list of limitation as array of strings
  def self.list
    KwalifyToJsonSchema::Options.parse
  end

  # @return limitation as markdown text
  def self.ascii_table(formatting = ["%s"] * 4)
    header = ["Name", "Type", "Default value", "Description"]

    nb_cols = header.length

    table = [header] +
            [[""] * nb_cols] +
            list.map { |o|
              [
                formatting[0] % o[:name].to_sym.inspect,
                formatting[1] % o[:type],
                formatting[2] % o[:default_value].inspect,
                formatting[3] % o[:description],
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
      }.join + "|"
    }.join "\n"
  end

  def self.markdown
    ascii_table [
      "`%s`",
      "`%s`",
      "`%s`",
      "_%s_",
    ]
  end

  def self.inject_as_code_comment(file)
    new_lines = []
    state = :init
    count = 0

    options_start = "Converter options:"
    options_stop = "--"

    File.read(file).each_line { |line|
      if line.strip.start_with? "#"
        content = line.strip[1..-1].strip
        case state
        when :init
          new_lines << line
          if content == options_start
            count += 1
            state = :in_options
            padding = line.index("#")
            new_lines.concat(ascii_table.lines.map { |l| "#{" " * padding}# #{l.chomp}\n" })
          end
        when :in_options
          if content.start_with? options_stop
            new_lines << line
            state = :init
          end
        end
      else
        state = :error unless state == :init
        new_lines << line
      end
    }

    if state == :error
      puts "Missing '#{options_stop}' delimiter after '#{options_start}' in file://#{file}"
    else
      File.write(file, new_lines.join) if count > 0
    end
  end
end
