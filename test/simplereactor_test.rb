require 'test_helper'
require 'simplereactor'

describe SimpleReactor do

  it "sets reactor to a select() based reactor when instructed to do so" do
    SimpleReactor.use_engine :select

    SimpleReactor.Reactor.must_be_same_as SimpleReactor::Select
  end

  it "sets reactor to a nio4r based reactor, if nio4r is available" do
    SimpleReactor.use_engine :nio

    if Object.const_defined? :NIO
      SimpleReactor.Reactor.must_be_same_as SimpleReactor::Nio

      SimpleReactor.use_engine :select

      SimpleReactor.Reactor.must_be_same_as SimpleReactor::Select

      SimpleReactor.use_engine :nio

      SimpleReactor.Reactor.must_be_same_as SimpleReactor::Select
    end
  end


end
