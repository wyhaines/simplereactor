require 'test_helper'
require 'simplereactor/select_monitor'

class MockIO; end

describe SimpleReactor::Select::Monitor do

  it "sets readable" do
    monitor = SimpleReactor::Select::Monitor.new(MockIO.new, :read)

    monitor.readable?.must_be :true?
    monitor.writeable?.wont_be :true?
  end

  it "sets writeable" do
    monitor = SimpleReactor::Select::Monitor.new(MockIO.new, :write)

    monitor.writeable?.must_be :true?
    monitor.readable?.wont_be :true?
  end

end
