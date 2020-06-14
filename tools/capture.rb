module Capture
  def self.with_captured_stdout
    original_stdout = $stdout  # capture previous value of $stdout
    $stdout = StringIO.new     # assign a string buffer to $stdout
    yield                      # perform the body of the user code
    $stdout.string             # return the contents of the string buffer
  ensure
    $stdout = original_stdout  # restore $stdout to its previous value
  end

  # Remove escape codes
  def self.clear_ansi_codes(str)
    result = ""
    escaped = false
    str.each_char.each { |c|
      if escaped
        if c == "m"
          escaped = false
        end
      else
        if c == "\x1b"
          escaped = true
        else
          result << c
        end
      end
    }
    result
  end
end
