require 'enumerator'

module SimpleReactor

  class LinkedList
    include Enumerable
      attr_accessor :head, :tail

    def initialize(&block)
      @head = Node.new
      @tail = Node.new
      @lookup = Hash.new
      @initializer = block
      join(@head,@tail)
    end

    def [](k)
      if !@lookup.has_key?( k ) && @initializer
        @initializer.call(self, k)
      end
      @lookup[k].value
    end

    def find(k)
      @lookup[k]
    end

    def []=(k,v)
      if @lookup.has_key?(k)
        @lookup[k].value = v
      else
        @lookup[k] = @head.insert_after(k,v)
      end
      v
    end

    def has_key?(k)
      @lookup.has_key?(k)
    end
    alias :include? :has_key?

    def empty?
      @lookup.empty?
    end

    def delete(n)
      if @lookup.has_key? n
        k = n
        n = @lookup[k]
      end
      @lookup.delete(n.key)
      join(n.previous,n.next)
      n.value
    end

    def first_node
      @head.next
    end

    def first
      first_node.value
    end

    def last_node
      @tail.previous
    end

    def last
      last_node.value
    end

    def shift
      k = @head.next.key
      n = @lookup.delete(k)
      delete(n) if n
    end

    def unshift(k, v = :_nil)
      v = v == :_nil ? k : v
      if @lookup.has_key?(k)
        n = @lookup[k]
        delete(n)
        @head.insert_after(n.key,n.value)
        @lookup[k] = n
      else
        @lookup[k] = @head.insert_after(k,v)
      end
      v
    end

    def pop
      k = @tail.previous.key
      n = @lookup.delete(k)
      delete(n) if n
    end

    def push(k, v = :_nil)
      v = v == :_nil ? k : v
      if @lookup.has_key?(k)
        n = @lookup[k]
        delete(n)
        @tail.insert_before(n.key, n.value)
        @lookup[k] = n
      else
        @lookup[k] = @tail.insert_before(k,v)
      end
      v
    end
    alias :<< :push

    def queue
      r = []
      n = @head
      while (n = n.next) and n != @tail
        r << n.key
      end
      r
    end
    alias :keys :queue

    def to_a
      r = []
      n = @head
      while (n = n.next) and n != @tail
        r << [n.key, n.value]
      end
      r
    end

    def length
      @lookup.length
    end

    def each
      n = @head
      while (n = n.next) and n != @tail
        yield(n.key,n.value)
      end
    end

    private

    def purge(n)
      join(n.previous,n.next)
      v = n.value
      n.value = nil
      n.key = nil
      n.next = nil
      n.previous = nil
      v
    end

    def join(a,b)
      a.next = b
      b.previous = a
    end

    class Node
      attr_accessor :key, :value, :previous, :next

      def initialize(*args)
        if Hash === args.first
          args = args.first
          key = args[:key]
          value = args[:value]
          prev_node = args[:previous]
          next_node = args[:next]
        else
          key,value,prev_node,next_node = *args
        end

        @key = key
        @value = value
        @previous = prev_node
        @next = next_node
      end

      def insert_before(k,v)
        new_node = Node.new(k, v, self.previous, self)
        self.previous.next = new_node
        self.previous = new_node
      end

      def insert_after(k,v)
        new_node = Node.new(k, v, self, self.next)
        self.next.previous = new_node
        self.next = new_node
      end

    end

  end
end
