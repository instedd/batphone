module Batphone
  module AgiMixin
    # Logger object, defaults to <tt>Logger.new(STDERR)</tt>. By default nothing
    # is logged, but if you turn up the log level to +DEBUG+ you'll see the
    # behind-the-scenes communication.
    attr_accessor :log

    # A Hash with the initial environment. Leave off the +agi_+ prefix
    def env
      @env ||= {}
    end
    alias :environment :env

    # Environment access shortcut. Use strings or symbols as keys.
    def [](key)
      env[key.to_s]
    end

    # Read a line from the environment. Returns +false+ on the empty line.
    def parse_env(line)
      line.strip!
      return false if line == ''

      k, v = line.split(':')
      k.strip! if k
      v.strip! if v
      k = $1 if k =~ /^agi_(.*)$/
      env[k] = v
      return true
    end

    # Build the raw data for the given command and arguments. Converts +nil+
    # and "" in +args+ to literal empty quotes
    def build_msg(cmd, *args)
      args.map! do |a|
        a = a.to_s
        a = (a.empty?) ? '""' : a
        a = "\"#{a}\"" if a.include? ' '
        a
      end
      [cmd, *args].join(' ')
    end

    # Shortcut for send_command. e.g.
    #     a.say_time(Time.now.to_i, nil)
    # is the same as
    #     a.send_command("SAY TIME",Time.now.to_i,'""')
    def method_missing(symbol, *args)
      cmd = symbol.to_s.upcase.tr('_',' ')
      send_command(cmd, *args)
    end

    # Repeat this menu followed by the timeout, with the given digits expected.
    # Use break to exit this menu.
    def menu(audio,digits,timeout=3000, &block)
      while true # (until the block breaks)
        r = self.stream_file(audio,digits)

        if r.result == 0
          # nothing was dialed yet, let's wait timeout milliseconds longer
          r = self.wait_for_digit(timeout)
        end
        yield(r) # if the block breaks, we go on with life
      end
    end

    # The answer to every AGI#send_command is one of these.
    class Response
      # Raw response string
      attr_accessor :raw
      # The return code, usually (almost always) 200
      attr_accessor :code
      # The result value (a string)
      attr_accessor :result
      # The note in parentheses (if any), stripped of parentheses
      attr_accessor :parenthetical
      alias :note :parenthetical
      # The endpos value (if any)
      attr_accessor :endpos

      # raw:: A string of the form "200 result=0 [(foo)] [endpos=1234]"
      #
      # The variables are populated as you would think. The parenthetical note is
      # stripped of its parentheses.
      #
      # Don't forget that result is often an ASCII value rather than an integer
      # value. In that case you should test against ?d where d is a digit.
      def initialize(raw)
        @raw = raw
        @raw =~ /^(\d+)\s+result=(-?[^\s]*)(?:\s+\((.*)\))?(?:\s+endpos=(-?\d+))?/
        @code = ($1 and $1.to_i)
        @result = $2
        @parenthetical = $3
        @endpos = ($4 and $4.to_i)
      end
    end
  end
end