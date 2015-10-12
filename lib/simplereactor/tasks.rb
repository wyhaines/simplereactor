require 'simplereactor/structures/sorted_linked_list'

module SimpleReactor
  class Tasks

    def initialize
      @tasks = SimpleReactor::LinkedList::Sorted.new {|ll, k| ll[k] = []}
    end

    def <<( task = nil, time_offset = nil, &block )
      if ( task.kind_of? Proc ) || ( block && ( task = block ) )
        time_offset ||= 0
        task = Task::Singular.new( time_offset, &task )
      end

      @tasks[task.trigger_time] = task
    end

    def call(*args)
      task_node = @tasks.first
      task = task_node.vale
      now = Time.now

      while task && task.trigger_time <= now
        case task.status
        when :pending
          task.call(*args)
        when :done
          @tasks.delete task_node
        end

        task = task_node.next
      end
    end
  end
end
