class NullObject
  def initialize
      @origin = caller.first
  end
  def method_missing(*args, &block)
    self
  end

  def nil?; true; end
end

def Maybe(value, &block)
  value.nil? ? (block.nil? ? NullObject.new : yield) : value
end