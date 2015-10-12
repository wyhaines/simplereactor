module SimpleReactor
  class Task
    attr_accessor :status

    def initialize( *args, &block )
      fail ArgumentError, "A task requires a block." unless block_given?

      if Hash === args.first
        args = args.first
        supervisor = args[:supervisor]
        block = args[:block] if args.has_key? :block
      else
        supervisor = args.first
      end

      @status = :pending
      @supervisor = supervisor
      @task = block
    end

    def call(*args)
      _invoke( *args )
    end

    def running
      @status = :running
    end

    def done
      @status = :done
    end

    def runnable?
      @status == :pending
    end

    def _invoke(*args)
      running
      @task.call( *([self].concat args) )
    ensure
      done
    end
  end
end