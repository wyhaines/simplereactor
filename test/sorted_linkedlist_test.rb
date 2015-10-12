require 'test_helper'
require 'simplereactor/structures/sorted_linked_list'

describe SimpleReactor::LinkedList::Sorted do
  before do
    @linkedlist = SimpleReactor::LinkedList::Sorted.new
  end

  it 'creates a simple list' do
    @linkedlist[ 10 ] = :a
    @linkedlist[ 20 ] = :b
    @linkedlist[ 30 ] = :c

    @linkedlist[ 10 ].must_equal :a
    @linkedlist[ 20 ].must_equal :b
    @linkedlist[ 30 ].must_equal :c
  end

  describe "when using a sorted linked list" do
    before do
      @linkedlist[ 10 ] = :a
      @linkedlist[ 20 ] = :b
      @linkedlist[ 30 ] = :c

      @linkedlist[ 10 ].must_equal :a
      @linkedlist[ 20 ].must_equal :b
      @linkedlist[ 30 ].must_equal :c
    end

    it "#has_key?" do
      @linkedlist.has_key?( 20 ).must_be :true?
      @linkedlist.has_key?( 99 ).must_be :false?
    end

    it "#empty?" do
      @linkedlist.empty?.must_be :false?
      SimpleReactor::LinkedList.new.empty?.must_be :true?
    end

    it "#find" do
      n = @linkedlist.find( 10 )
      n.must_be_instance_of SimpleReactor::LinkedList::Node
      n.value.must_equal :a
    end

    it "#length" do
      @linkedlist.length.must_equal 3
    end

    it "#first" do
      @linkedlist.first.must_equal :a
    end

    it "#last" do
      @linkedlist.last.must_equal :c
    end

    it "#shift" do
      val = @linkedlist.shift
      val.must_equal :a
      @linkedlist.length.must_equal 2
    end

    it "#unshift" do
      @linkedlist.unshift(40, :d)
      @linkedlist.first.must_equal :a
      @linkedlist.last.must_equal :d
      @linkedlist.length.must_equal 4

      @linkedlist.unshift(10)
      @linkedlist.first.must_equal :a
      @linkedlist.last.must_equal :d
      @linkedlist.length.must_equal 4

      @linkedlist.unshift(260, :z)
      @linkedlist.first.must_equal :a
      @linkedlist.last.must_equal :z
      @linkedlist.length.must_equal 5
      @linkedlist[260].must_equal :z
    end

    it "#pop" do
      val = @linkedlist.pop
      val.must_equal :c
      @linkedlist.length.must_equal 2
    end

    it "#push" do
      @linkedlist.push(40, :d)
      @linkedlist.first.must_equal :a
      @linkedlist.last.must_equal :d
      @linkedlist.length.must_equal 4

      @linkedlist.push(10)
      @linkedlist.first.must_equal :a
      @linkedlist.last.must_equal :d
      @linkedlist.length.must_equal 4

     @linkedlist.push(260, :z)
      @linkedlist.first.must_equal :a
      @linkedlist.last.must_equal :z
      @linkedlist.length.must_equal 5
      @linkedlist[260].must_equal :z
    end

    it "#queue" do
      q = @linkedlist.queue
      q.must_equal [10, 20, 30]
    end

    it "#to_a" do
      ary = @linkedlist.to_a
      ary.must_equal [[10, :a], [20, :b], [30, :c]]
    end

    it "#delete" do
      @linkedlist.delete(20)
      first_node = @linkedlist.first_node
      last_node = @linkedlist.last_node
      first_node.value.must_equal :a
      last_node.value.must_equal :c
      first_node.next.must_equal last_node
      last_node.previous.must_equal first_node
    end

    it "#each" do
      expected_kv = [[10, :a], [20, :b], [30, :c]]
      @linkedlist.each do |k,v|
        expected_key, expected_value = expected_kv.shift
        k.must_equal expected_key
        v.must_equal expected_value
      end
    end

  end
end
