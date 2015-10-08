# Simple; not particularly efficient for many entries.
# TODO: Make this an implementation that isn't horrible when there are a lot of timers.
module SimpleReactor

  class TimerMap < Hash

    def []=(k,v)
      if self.has_key? k
        self[k] << v
      else
        super(k,[v])
      end
      @sorted_keys = keys.sort
      v
    end

    def delete k
      r = super
      @sorted_keys = keys.sort
      r
    end

    def next_time
      @sorted_keys.first
    end

    def shift
      if @sorted_keys.empty?
        nil
      else
        first_key = @sorted_keys.first
        val = self[first_key].shift

        if self[first_key].empty?
          @sorted_keys.shift
          self.delete first_key
        end

        [first_key, val]
      end
    end

    def add_timer time, *args, &block
      time = case time
      when Time
        time
      else
        Time.now + time.to_f
      end

      self[time] = [block, args] if block
    end

    def call_next_timer
      _, v = self.shift
      block, args = v
      block.call(*args)
    end

    def ready?
      next_time && next_time <= Time.now
    end

    def call
      results = []

      while ready? do
        results << call_next_timer
      end

      results.empty? ? nil : results
    end
  end

end
