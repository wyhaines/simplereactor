require 'simplereactor/timermap'
require 'simplereactor/monkeys'

module SimpleReactor

  class Core

    Events = [:read, :write, :error].freeze
    attr_reader :ios

    def self.run &block
      SimpleReactor.use_engine :nio unless SimpleReactor.engine_initialized?

      reactor = Reactor.new

      reactor.run( &block )
    end

    def initialize
      @running = false

      @timers = TimerMap.new
      @block_buffer = []
      initialize_ios_data_structure
    end

    def attach io, *args, &block
      events = Events & args
      args -= events

      @ios[io][:events] |= events

      register_monitors io, events, *args, &block

      self
    end

    def detach io
      @ios.delete io
      deregister_monitor io
    end

    def deregister_monitor io
      # Override in subclass, as necessary
    end

    def add_timer time, *args, &block
      time = time.to_i if Time === time
      @timers.add_timer time, *args, &block
    end

    def next_tick &block
      @block_buffer << block
    end

    def tick
      handle_pending_blocks
      handle_events
      handle_timers
    end

    def run
      @running = true

      yield self if block_given?

      tick while @running
    end

    def stop
      @running = false
    end

    def handle_pending_blocks
      @block_buffer.length.times { @block_buffer.shift.call }
    end

    def handle_timers
      now = Time.now
      while !@timers.empty? && @timers.next_time < now
        @timers.call_next_timer
      end
    end

    def empty?
      @ios.empty? && @timers.empty? && @block_buffer.empty?
    end

  end
end
