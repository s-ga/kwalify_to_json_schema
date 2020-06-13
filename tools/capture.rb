module Capture
  def self.with_captured_stdout
    original_stdout = $stdout  # capture previous value of $stdout
    $stdout = StringIO.new     # assign a string buffer to $stdout
    yield                      # perform the body of the user code
    $stdout.string             # return the contents of the string buffer
  ensure
    $stdout = original_stdout  # restore $stdout to its previous value
  end
end
