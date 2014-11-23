require 'nio'

module SimpleReactor
  
  class Nio < Core

    def initialize
      super
      @selector = NIO::Selector.new
    end

    def register_monitors io, events, *args, &block
      if SimpleReactor::Core::Events.has_any_of?( *events )
        i = @ios[io]
        i[:events] = events
        
        if ( events.include? :read ) && ( events.include? :write ) 
          i[:monitors] = @selector.register( io, :rw )
        elsif events.include? :read
          i[:monitors] = @selector.register( io, :r )
        elsif events.include? :write
          i[:monitors] = @selector.register( io, :w )
        end
        
        i[:monitors].value = [block,args] if i[:monitors]
      end
    end
    
    def deregister_monitor io
      @selector.deregister io
    end
    
    def handle_events
      @selector.select(0) do |monitor|
        monitor.value.first.call(monitor, *monitor.value.last)
      end
    end
    
    def initialize_ios_data_structure
      @ios = Hash.new do |h,k|
        h[k] = {
          :events => [],
          :monitors => nil
        }
      end
    end
    
  end
  
  Reactor = Nio
  
end
