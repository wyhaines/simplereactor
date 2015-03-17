class Array
  def has_any_of?(*args)
    self.any? {|x| args.include? x}
  end
end