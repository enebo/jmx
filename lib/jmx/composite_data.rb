require 'java'

module javax::management::openmbean::CompositeData
  include Enumerable

  def [](key)
    get(key.to_s)
  end

  def method_missing(name, *args)
    self[name]
  end

  def each
    get_composite_type.key_set.each { |key| yield key }
  end

  def each_pair
    get_composite_type.key_set.each { |key| yield key, get(key) }
  end
end
