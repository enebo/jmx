module JMX
  import javax.management.MBeanParameterInfo
  import javax.management.MBeanOperationInfo
  import javax.management.MBeanAttributeInfo
  import javax.management.MBeanInfo

  module JavaTypeAware
    SIMPLE_TYPES = {
      :int => ['java.lang.Integer', lambda {|param| param.to_i}],
      :list => ['java.util.List', lambda {|param| param.to_a}],
      :long => ['java.lang.Long', lambda {|param| param.to_i}],
      :float => ['java.lang.Float', lambda {|param| param.to_f}],
      :map => ['java.util.Map', lambda {|param| param}],
      :set => ['java.util.Set', lambda {|param| param}],
      :string => ['java.lang.String', lambda {|param| "'#{param.to_s}'"}],
      :void => ['java.lang.Void', lambda {|param| nil}]
    }

    def to_java_type(type_name)
      SIMPLE_TYPES[type_name][0] || type_name
    end
    #TODO: I'm not sure this is strictly needed, but funky things can happen if you 
    # are expecting your attributes (from the ruby side) to be ruby types and they are java types.
    def to_ruby(type_name)
      SIMPLE_TYPES[type_name][1] || lambda {|param| param}
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
  
  
  class Attribute < Struct.new(:name, :type, :description, :is_reader, :is_writer, :is_iser)
    include JavaTypeAware
    
    def initialize(name, type, description, is_rdr, is_wrtr)
      super
      self.description, self.type, self.name = description, type, name
      self.is_reader,self.is_writer, self.is_iser = is_rdr, is_wrtr, false
    end

    def to_jmx
      MBeanAttributeInfo.new(name.to_s, to_java_type(type), description, is_reader, is_writer, is_iser) 
    end
  end
end


=begin rdoc
  Inherit from this class to create your own ruby based dynamic MBean
=end
class RubyDynamicMBean
  import javax.management.MBeanOperationInfo
  import javax.management.MBeanAttributeInfo
  include JMX::JavaTypeAware
  
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

  #methods used to create an attribute.  They are modeled on the attrib_accessor
  # patterns of creating getters and setters in ruby
  def self.rw_attribute(name, type, description)
    #QUESTION: Is this here to ensure that our type implements the interface?
    include DynamicMBean
    attributes << JMX::Attribute.new(name, type, description, true, true).to_jmx
    attr_accessor name    
    #create a "java" oriented accessor method
    define_method("jmx_get_#{name.to_s.downcase}") do 
      begin
        #attempt conversion
        java_type = to_java_type(type)
        value = eval "#{java_type}.new(@#{name.to_s})"
      rescue
        #otherwise turn it into a java Object type for now.  
        value = eval "Java.ruby_to_java(@#{name.to_s})"
      end
      attribute = javax.management.Attribute.new(name.to_s, value)
    end

    define_method("jmx_set_#{name.to_s.downcase}") do |value| 
      blck = to_ruby(type)
      eval "@#{name.to_s} = #{blck.call(value)}"
    end
    
  end
  # used to create a read only attribute
  def self.r_attribute(name, type, description)
    include DynamicMBean        
    attributes << JMX::Attribute.new(name, type, description, true, false).to_jmx
    attr_reader name
    #create a "java" oriented accessor method
    define_method("jmx_get_#{name.to_s.downcase}") do 
      begin
        #attempt conversion
        java_type = to_java_type(type)
        value = eval "#{java_type}.new(@#{name.to_s})"
      rescue
        #otherwise turn it into a java Object type for now.  
        value = eval "Java.ruby_to_java(@#{name.to_s})"
      end
      attribute = javax.management.Attribute.new(name.to_s, value)
    end
  end
  # used to create a read only attribute
  def self.w_attribute(name, type, description)
    include DynamicMBean        
    attributes << JMX::Attribute.new(name, type, description, false, true).to_jmx
    attr_writer name
    define_method("jmx_set_#{name.to_s.downcase}") do |value|
      blck = to_ruby(type)
      eval "@#{name.to_s} = #{blck.call(value)}"
    end
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
    attributes = self.class.attributes.to_java(MBeanAttributeInfo)
    @info = MBeanInfo.new name, description, attributes, nil, operations, nil
  end

  def getAttribute(attribute)
    send("jmx_get_"+attribute.downcase)
  end
  
  def getAttributes(attributes)
    attrs = javax.management.AttributeList.new
    attributes.each { |attribute| attrs.add(getAttribute(attribute)) } 
    attrs
  end
  
  def getMBeanInfo; @info; end
  
  def invoke(actionName, params=nil, signature=nil)
    send(actionName, *params)
  end

  def setAttribute(attribute)
    send("jmx_set_#{attribute.name.downcase}", attribute.value)   
  end
  
  def setAttributes(attributes)  
    attributes.each { |attribute| setAttribute attribute}
  end
  
  def to_s; toString; end
  def inspect; toString; end
  def toString; "#@info.class_name: #@info.description"; end
end
