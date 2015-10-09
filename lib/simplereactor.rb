require 'simplereactor/version'
require 'simplereactor/core'

# Prefer nio4r, but fall back to using select if necessary.

module SimpleReactor

  def self.Reactor
    @reactor
  end

  def self.Reactor=(val)
    @reactor = val
  end

  def self.use_engine( engine )
    case engine
    when :nio
      require 'simplereactor/nio'
      puts "GOT NIO"
      SimpleReactor::Nio.is_reactor_engine
    when :select
      require 'simplereactor/select'
      SimpleReactor::Select.is_reactor_engine
    end
  rescue LoadError
    require 'simplereactor/select'
    SimpleReactor::Select.is_reactor_engine
  ensure
    unless SimpleReactor.Reactor
      require 'simplereactor/select'
      SimpleReactor::Select.is_reactor_engine
    end
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
