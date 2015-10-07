require 'test_helper'
require 'simplereactor/timermap'

describe SimpleReactor::TimerMap do
  before do
    @timers = SimpleReactor::TimerMap.new
  end

  describe "when using a timer map" do

    it "should all timers to be added using specific times" do
      now = Time.now
      @timers.add_timer( ( now + 5 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 10 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }
      @timers.add_timer( ( now + 15 ), 1, 2, 3 ) {|args| args.inject(0) {|a,x| a += x; a} }

      @timers.keys.length.must_equal 3
    end
  end
end
