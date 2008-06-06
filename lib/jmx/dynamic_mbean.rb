module JMX
  import javax.management.MBeanParameterInfo
  import javax.management.MBeanOperationInfo
  import javax.management.MBeanInfo

  module JavaTypeAware
    SIMPLE_TYPES = {
      :int => 'java.lang.Integer',
      :list => 'java.util.List',
      :long => 'java.lang.Long',
      :map => 'java.util.Map',
      :set => 'java.util.Set',
      :string => 'java.lang.String',
      :void => 'java.lang.Void'
    }

    def to_java_type(type_name)
      SIMPLE_TYPES[type_name] || type_name
    end
  end

  class Parameter
    include JavaTypeAware 

    def initialize(type, name, description)
      @type, @name, @description = type, name, description
    end

    def to_jmx
      MBeanParameterInfo.new @name.to_s, to_java_type(@type), @description
    end
  end

  class Operation < Struct.new(:description, :parameters, :return_type, :name, :impact)
    include JavaTypeAware

    def initialize(description)
      super
      self.parameters, self.impact, self.description = [], MBeanOperationInfo::UNKNOWN, description
    end

    def to_jmx
      java_parameters = parameters.map { |parameter| parameter.to_jmx }
      MBeanOperationInfo.new name.to_s, description, java_parameters.to_java(javax.management.MBeanParameterInfo), to_java_type(return_type), impact
    end
  end    
end

class RubyDynamicMBean
  import javax.management.MBeanOperationInfo
  
  # TODO: preserve any original method_added?
  # TODO: Error handling here when it all goes wrong?
  def self.method_added(name)
    return if Thread.current[:op].nil?
    Thread.current[:op].name = name
    operations << Thread.current[:op].to_jmx
    Thread.current[:op] = nil
  end

  def self.attributes
    Thread.current[:attrs] ||= []
  end
  
  def self.operations
    Thread.current[:ops] ||= []
  end

  # Last operation wins if more than one
  def self.operation(description)
    include DynamicMBean

    # Wait to error check until method_added so we can know method name
    Thread.current[:op] = JMX::Operation.new description
  end

  def self.parameter(type, name=nil, description=nil)
    Thread.current[:op].parameters << JMX::Parameter.new(type, name, description)
  end

  def self.returns(type)
    Thread.current[:op].return_type = type
  end
  
  def initialize(name, description)
    operations = self.class.operations.to_java(MBeanOperationInfo)
    @info = MBeanInfo.new name, description, nil, nil, operations, nil
  end

  def getAttribute(attribute); $stderr.puts "getAttribute"; end
  def getAttributes(attributes); $stderr.puts "getAttributes"; end
  def getMBeanInfo; @info; end
  def invoke(actionName, params=nil, signature=nil)
    send(actionName, *params)
  end
  def setAttribute(attribute); $stderr.puts "setAttribute"; end
  def setAttributes(attributes); $stderr.puts "setAttributes";  end
  def to_s; toString; end
  def inspect; toString; end
  def toString; "#@info.class_name: #@info.description"; end
end
