require 'simplereactor/core'

# Prefer nio4r, but fall back to using select if necessary.

begin
  require 'simplereactor/nio'
rescue LoadError
  require 'simplereactor/select'
end