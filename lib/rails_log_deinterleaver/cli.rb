require 'trollop'

module RailsLogDeinterleaver
  class Cli
    def initialize
      opts = Trollop::options do
        opt :output, "Output file (if unspecified, output will go to stdout)", type: :string
        opt :backward, "Limit how many lines to go backward (default: no limit)", type: :integer
      end
      input = ARGV.last
      if opts[:output]
        opts[:output] = File.new(opts[:output], 'w')
      end
      raise 'Must specify input log file' unless input && File.exist?(input)

      Parser.new(input, opts).run
    end
  end
end
