module SimpleReactor
  class Select < Core
    class Monitor
      attr_accessor :io, :value

      def initialize( io_obj, event, val = nil)
        @io = io_obj
        @value = val

        case event
        when :read
          set_readable
        when :write
          set_writeable
        else
          raise "Illegal event type; monitor must be either :read or :write"
        end
      end

      def readable?
        @readable_attribute
      end

      def writeable?
        @writeable_attribute
      end

      def set_readable
        @readable_attribute = true
      end

      def set_writeable
        @writeable_attribute = true
      end

    end
  end
end