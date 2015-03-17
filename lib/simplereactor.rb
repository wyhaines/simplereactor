require 'simplereactor/version'
require 'simplereactor/core'

# Prefer nio4r, but fall back to using select if necessary.

module SimpleReactor
  
  def self.use_engine( engine )
    case engine
    when :nio
      require 'simplereactor/nio'
    when :select
      require 'simplereactor/select'
    end
  rescue LoadError
    require 'simplereactor/select'
  ensure
    require 'simplereactor/select' unless SimpleReactor.const_defined?( :Reactor ) && SimpleReactor::Reactor
    initialize_engine
  end
  
  def self.engine_initialized?
    @initialized
  end
  
  def self.initialize_engine
    @initialized = true
  end
  
  begin
    require 'simplereactor/nio'
  rescue LoadError
    require 'simplereactor/select'
  end

end
