require 'simplereactor/select_monitor'

module SimpleReactor
  
  class Select < Core

    def register_monitors io, events, *args, &block
      i = @ios[io]
      events.each {|event|  i[:callbacks][event] = block }
      i[:args] = args
      i
    end

    def handle_pending_blocks
      @block_buffer.length.times { @block_buffer.shift.call }
    end

    def handle_events
      unless @ios.empty?
        pending_events.each do |io, events|
          events.each do |event|
            if @ios.has_key? io
              if handler = @ios[io][:callbacks][event]
                monitor = Monitor.new( io, event, [handler, @ios[io][:args]] )
                handler.call monitor, *@ios[io][:args]
              end
            end
          end
        end
      end
    end

    def pending_events
      # Trim our IO set to only include those which are not closed.
      @ios.reject! {|io, v| io.closed? }
  
      h = find_handles_with_events @ios.keys
  
      if h
        handles = Events.zip(h).inject({}) {|hndl, ev| hndl[ev.first] = ev.last; hndl}
  
        events = Hash.new {|hash,k| hash[k] = []}
  
        Events.each do |event|
          handles[event].each { |io| events[io] << event }
        end
  
        events
      else
        {} # No handles
      end
    end

    def find_handles_with_events keys
      select find_ios(:read), find_ios(:write), keys, 0.1
    end
  
    def find_ios event
      @ios.select { |io, h| h[:events].include? event}.collect { |io, data| io }
    end
    
    def initialize_ios_data_structure
      @ios = Hash.new do |h,k|
        h[k] = {
          :events => [],
          :callbacks => {},
          :args => []
        }
      end
    end
    
  end
  
  Reactor = Select
  
end