require 'simplereactor/task'

#####
#
# SimpleReactor::Task::Singular
#
# A task that happens only a single time.
#
#####

module SimpleReactor
  class Task
    class Singular < SimpleReactor::Task

      attr_accessor :trigger_time

      def initialize(*args, &block)
        super

        if Hash === args.first
          args = args.first
          trigger_time = args[:time] || Time.now
        else
          trigger_time = args[1]
        end

        @trigger_time = Time === trigger_time ? trigger_time : ( Time.now + trigger_time )
      end

      def runnable?
        super && Time.now >= @trigger_time
      end
    end
  end
end
