require 'test_helper'
require 'simplereactor/timermap'

describe SimpleReactor::TimerMap do
  before do
    @timers = SimpleReactor::TimerMap.new
  end

  describe "when using a timer map" do

    it "should allow timers to be added using specific times" do
      now = Time.now
      @timers.add_timer( ( now + 5 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 10 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 15 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }

      @timers.keys.length.must_equal 3
    end

    it "should allow timers to be added using an offset" do
      @timers.add_timer( 5, 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( 10, 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( 15, 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }

      @timers.keys.length.must_equal 3
    end

    it "should report the next timer in line to be triggered" do
      now = Time.now
      @timers.add_timer( ( now + 5 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 10 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }

      @timers.next_time.must_equal( now + 5 )
    end

    it "should know when a timer is ready to trigger" do
      now = Time.now
      @timers.add_timer( ( now + 1 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 3 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }

      @timers.ready?.must_be :false?
    end

    it "should call timers when they are ready, and return the expected result sets" do
      now = Time.now
      @timers.add_timer( ( now + 1 ), 1, 2, 3 ) {|*args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 3 ), 2, 3, 4 ) {|*args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 3 ), 3, 4, 5 ) {|*args| args.inject(0) {|a,x| a += x; a} }

      @timers.call.must_be :nil?

      sleep 1
      results = @timers.call
      results.wont_be_empty
      results.length.must_equal 1
      results.first.must_equal 6

      sleep 2
      results = @timers.call
      results.wont_be_empty
      results.length.must_equal 2
      results[0].must_equal 9
      results[1].must_equal 12

      @timers.ready?.must_be :false?
      @timers.any?.must_be :false?
    end

  end
end
