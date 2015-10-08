$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplereactor'

require 'minitest/autorun'

class Object
  def false?
    self ? false : true
  end

  def true?
    self ? true : false
  end
end
