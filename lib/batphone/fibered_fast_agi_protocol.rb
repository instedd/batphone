module Batphone
  class FiberedFastAgiProtocol < FastAgiProtocol

    def initialize
      class << self
        alias_method :agi_post_init_without_fibers, :agi_post_init
        def agi_post_init
          f = Fiber.new do
            agi_post_init_without_fibers
          end
          f.resume
        end
      end
      super
    end

    def send_command(cmd, *args)
      f = Fiber.current
      deferrable = super(cmd, *args)
      deferrable.callback do |line|
        f.resume line
      end
      deferrable.errback do |error|
        f.resume Exception.new error
      end
      Fiber.yield
    end

  end
end