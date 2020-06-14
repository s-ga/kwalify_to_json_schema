module Cli
  def self.help(*args)
    Capture.clear_ansi_codes(Capture.with_captured_stdout {
      KwalifyToJsonSchema::Cli.start(["help"] + args)
    })
  end
end
