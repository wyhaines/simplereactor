# Simple; not particularly efficient for many entries.
# TODO: Make this an implementation that isn't horrible when there are a lot of timers.
module SimpleReactor

  class TimerMap < Hash
    def []=(k,v)
      super
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
        first_key = @sorted_keys.shift
        val = self.delete first_key
        [first_key, val]
      end
    end

    def add_timer time, *args, &block
      time = case time
      when Time
        Time.to_i
      else
        Time.now + time.to_i
      end

      self[time] = [block, args] if block
    end

    def call_next_timer
      _, v = self.shift
      block, args = v
      block.call(*args)
    end
  end

end
