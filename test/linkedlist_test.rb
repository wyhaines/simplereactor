require 'test_helper'
require 'simplereactor/structures/linked_list'

describe SimpleReactor::LinkedList::Node do
  it 'can be created with a simple list of arguments' do
    node = SimpleReactor::LinkedList::Node.new('key', 'value', :mock_previous, :mock_next)

    node.must_be_instance_of SimpleReactor::LinkedList::Node
    node.key.must_equal 'key'
    node.value.must_equal 'value'
    node.previous.must_equal :mock_previous
    node.next.must_equal :mock_next
  end

  it 'can be created with a hash of arguments' do
    node = SimpleReactor::LinkedList::Node.new(key: 'key', value: 'value', previous: :mock_previous, next: :mock_next)

    node.must_be_instance_of SimpleReactor::LinkedList::Node
    node.key.must_equal 'key'
    node.value.must_equal 'value'
    node.previous.must_equal :mock_previous
    node.next.must_equal :mock_next
  end
end

describe SimpleReactor::LinkedList do
  before do
    @linkedlist = SimpleReactor::LinkedList.new
  end

  it 'creates a simple list' do
    @linkedlist[ :a ] = 1
    @linkedlist[ :b ] = 2
    @linkedlist[ :c ] = 3

    @linkedlist[ :a ].must_equal 1
    @linkedlist[ :b ].must_equal 2
    @linkedlist[ :c ].must_equal 3
  end

  describe "when using a linked list" do
    before do
      @linkedlist[ :a ] = 1
      @linkedlist[ :b ] = 2
      @linkedlist[ :c ] = 3

      @linkedlist[ :a ].must_equal 1
      @linkedlist[ :b ].must_equal 2
      @linkedlist[ :c ].must_equal 3
    end

    it "#has_key?" do
      @linkedlist.has_key?( :b ).must_be :true?
      @linkedlist.has_key?( :z ).must_be :false?
    end

    it "#empty?" do
      @linkedlist.empty?.must_be :false?
      SimpleReactor::LinkedList.new.empty?.must_be :true?
    end

    it "#find" do
      n = @linkedlist.find( :a )
      n.must_be_instance_of SimpleReactor::LinkedList::Node
      n.value.must_equal 1
    end

    it "#length" do
      @linkedlist.length.must_equal 3
    end

    it "#first" do
      @linkedlist.first.must_equal 3
    end

    it "#last" do
      @linkedlist.last.must_equal 1
    end

    it "#shift" do
      val = @linkedlist.shift
      val.must_equal 3
      @linkedlist.length.must_equal 2
    end

    it "#unshift" do
      @linkedlist.unshift(4)
      @linkedlist.first.must_equal 4
      @linkedlist.last.must_equal 1
      @linkedlist.length.must_equal 4

      @linkedlist.unshift(:a)
      @linkedlist.first.must_equal 1
      @linkedlist.last.must_equal 2
      @linkedlist.length.must_equal 4

      @linkedlist.unshift(:z, 26)
      @linkedlist.first.must_equal 26
      @linkedlist.last.must_equal 2
      @linkedlist.length.must_equal 5
      @linkedlist[:z].must_equal 26
    end

    it "#pop" do
      val = @linkedlist.pop
      val.must_equal 1
      @linkedlist.length.must_equal 2
    end

    it "#push" do
      @linkedlist.push(4)
      @linkedlist.first.must_equal 3
      @linkedlist.last.must_equal 4
      @linkedlist.length.must_equal 4

      @linkedlist.push(:a)
      @linkedlist.first.must_equal 3
      @linkedlist.last.must_equal 1
      @linkedlist.length.must_equal 4

      @linkedlist.push(:z, 26)
      @linkedlist.first.must_equal 3
      @linkedlist.last.must_equal 26
      @linkedlist.length.must_equal 5
      @linkedlist[:z].must_equal 26
    end

    it "#queue" do
      q = @linkedlist.queue
      q.must_equal [:c, :b, :a]
    end

    it "#to_a" do
      ary = @linkedlist.to_a
      ary.must_equal [[:c, 3], [:b, 2], [:a, 1]]
    end

    it "#delete" do
      @linkedlist.delete(:b)
      first_node = @linkedlist.first_node
      last_node = @linkedlist.last_node
      first_node.value.must_equal 3
      last_node.value.must_equal 1
      first_node.next.must_equal last_node
      last_node.previous.must_equal first_node
    end

    it "#each" do
      expected_kv = [[:c, 3], [:b, 2], [:a, 1]]
      @linkedlist.each do |k,v|
        expected_key, expected_value = expected_kv.shift
        k.must_equal expected_key
        v.must_equal expected_value
      end
    end

  end
end
