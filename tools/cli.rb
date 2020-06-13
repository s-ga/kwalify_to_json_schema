module Cli
  def self.help
    Capture.with_captured_stdout {
      KwalifyToJsonSchema::Cli.start(["help"])
    }
  end
end
