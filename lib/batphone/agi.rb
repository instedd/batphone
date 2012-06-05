module Batphone
  class Agi
    include AgiMixin

    # Create a new AGI object and parse the Asterisk environment. Usually you
    # will call this without arguments, but you might have your bat-reasons to
    # provide +io_in+ and +io_out+.
    #
    # Also sets up a default SIGHUP trap, logging the event and calling exit. If
    # you want to do some cleanup on SIGHUP instead, override it, e.g.:
    #     trap('SIGHUP') { cleanup }
    def initialize(io_in=STDIN, io_out=STDOUT)
      @io_in = io_in
      @io_out = io_out

      loop do
        break if not parse_env @io_in.readline
      end

      @log = Logger.new(STDERR)

      @args = ARGV

      # default trap for SIGHUP, which is what Asterisk sends us when the other
      # end hangs up. An uncaught SIGHUP exception pollutes STDERR needlessly.
      trap('SIGHUP') { @log.debug('Holy SIGHUP, Batman!'); exit }
    end

    # The arguments passed in the Asterisk AGI application, so
    #     _X,1,AGI(foo.agi|one|two|three)
    # will give agi.args as ["one","two","three"].
    attr_reader :args
    alias :argv :args

    # Send a command, wait, and return the Response object.
    def send_command(cmd, *args)
      msg = build_msg(cmd, *args)
      @log.debug ">> "+msg if not @log.nil?
      @io_out.puts msg
      @io_out.flush # I'm not sure if this is necessary, but just in case

      resp = @io_in.readline
      @log.debug "<< "+resp if not @log.nil?
      Response.new(resp)
    end
  end
end