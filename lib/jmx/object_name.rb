require 'java'
java_import javax.management.ObjectName

class ObjectName
  def [](key)
    get_key_property(key.to_s)
  end
  
  def info(server)
    server.getMBeanInfo(self)
  end

  ##
  # Make a new ObjectName unless it is already one
  def self.make(name)
    return name if name.kind_of? ObjectName

    ObjectName.new name
  rescue Exception
    raise ArgumentError.new("Invalid ObjectName #{$!.message}")
  end
end
