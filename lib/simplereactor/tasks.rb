require 'simplereactor/structures/sorted_linked_list'
require 'simplereactor/task/singular'
require 'simplereactor/task/persistent'
require 'simplereactor/task/repeating'

module SimpleReactor
  class Tasks

    def initialize
      @tasks = SimpleReactor::LinkedList::Sorted.new {|linked_list, key| linked_list[key] = []}
      @task_times = Hash.new
    end

    def <<( task = nil, time_offset = nil, &block )
      if ( task.kind_of? Proc ) || ( block && ( task = block ) )
        time_offset ||= 0
        task = Task::Singular.new( time_offset, &task )
      end

      @task_times[task] = task.trigger_time
      @tasks[task.trigger_time] = task
    end

    def call( *args )
      task_node = @tasks.first
      task = task_node.vale
      now = Time.now

      while task && task.trigger_time <= now
        case task.status
        when :pending
          task.call( *args )
        when :done
          @tasks.delete task_node
          task.cleanup( self )
        end

        task = task_node.next
      end
    end

    def delete( task )
      if @tasks[@task_times[task]] == task
        @tasks.delete( task )
      elsif ( ( Array === @tasks[@task_times[task]] ) && ( @tasks[@task_times[task].include?( task )] ) )
        @tasks[task].delete task
      else
        false
      end
    end
  end
end
