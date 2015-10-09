require 'test_helper'
require 'simplereactor/timermap'

describe Array do
  it "#has_any_of works" do
    ary = (1..100).to_a

    ary.has_any_of?(1,2,3,5,7,11,13,17,19,23).must_be :true?
    ary.has_any_of?(101,102,103,105,107,1011,1013,1017,1019,1023).must_be :false?
    ary.has_any_of?(101,102,103,105,107,1011,1013,17,1019,1023).must_be :true?
  end
end
