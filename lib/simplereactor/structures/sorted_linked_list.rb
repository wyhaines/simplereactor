require 'simplereactor/structures/linked_list'

module SimpleReactor

  class LinkedList

    class Sorted < SimpleReactor::LinkedList

      def initialize
        super
        @key_positions = []
      end

      def []=(k,v)
        if @lookup.has_key?(k)
          @lookup[k].value = v
        else
          if @key_positions.empty? || ( k <= @key_positions.first )
            @lookup[k] = @head.insert_after(k,v)
            action = [ :unshift, k ]
          elsif k >= @key_positions.last
            @lookup[k] = @tail.insert_before(k,v)
            action = [ :push, k ]
          else
            target = find_closest_value(k)
            if target
              target_node = find( target )
              action = [ :insert, @key_positions.index( target ), k ]
            else
              target_node = @tail
              action = [ :insert, @key_positions.length, k ]
            end
            @lookup[k] = target_node.insert_before(k,v)
          end
          @key_positions.__send__(*action)
        end
        v
      end

      def delete(n)
        if @lookup.has_key? n
          k = n
          n = @lookup[k]
        end
        k = n.key
        @lookup.delete(k)
        @key_positions.delete(k)
        join(n.previous,n.next)
        n.value
      end

      def unshift(k, v = :_nil) # since the data set is always sorted, unshift == normal insert
        if v == :_nil
          if @lookup.has_key?( k )
            v = @lookup[k].value
          else
            v = k
          end
        end
        self[k] = v
      end

      def push(k, v = :_nil) # since the data set is always sorted, push == normal insert
        if v == :_nil
          if @lookup.has_key?( k )
            v = @lookup[k].value
          else
           v = k
          end
        end
        self[k] = v
      end

      def find_closest_value(target)
        @key_positions.bsearch {|pos| target <= x}
      end

    end
  end
end
