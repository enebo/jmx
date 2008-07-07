
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'rmi'
require 'jmx'


class MyAttributeDynamicBean < RubyDynamicMBean
  rw_attribute :name1, :string, "My sample attribute"
  r_attribute :number1, :int, "My sample integer based attribute that is read only"
  w_attribute :number2, :int, "My sample integer based attribute that is write only"

  def intialize(type, text)
    super(type,text)
  end
  def set_number1(val)
    @number1 = val
  end
  
  def fetch_number2
    @number2
  end
end

class JMXAttributeTest < Test::Unit::TestCase
  
  def setup
    @madb = MyAttributeDynamicBean.new("test.MyTestBean","Mwahahahahahah")    
  end
  
  #make sure we didn't break anything from a ruby perspective
  def test_can_create_bean_and_access_accessor_type_methods
    @madb.set_number1 4
    assert_nil(@madb.name1)
    @madb.name1 = "Name"
    assert_equal("Name", @madb.name1)
    assert_equal(4, @madb.number1)
    @madb.number2 = 4
    assert_equal(4, @madb.fetch_number2)    
    assert_raise(NoMethodError) { @madb.number2 }    
  end

  def test_get_attributes_via_dynamicmbeaninterface
    @madb.set_number1 4
    @madb.name1 = "Name"

    assert_equal(@madb.name1, @madb.getAttribute("name1").get_value.to_s)
    assert_equal(@madb.number1, @madb.getAttribute("number1").get_value)    
    atts = ["name1", "number1"]
    retrieved = @madb.getAttributes(atts)
    assert_equal(2, retrieved.length)
    #TODO: assertion comparing the types in teh array to java types
  end
  
  def test_set_attributes_via_dynamicbeaninterface
    @madb.name1 = "blue"
    red = java.lang.String.new("red")
    attribute = javax.management.Attribute.new("name1", red)
    @madb.setAttribute(attribute)

    assert_equal("String", @madb.name1.class.to_s )
    assert_equal("red", @madb.name1)
  end
  
  def test_set_multiple_attributes_via_dynamicbeaninterface
    @madb.name1 = "blue"
    three = java.lang.Integer.new(3)
    red = java.lang.String.new("red")
    attribute1 = javax.management.Attribute.new("name1", red)
    attribute2 = javax.management.Attribute.new("number2", three)
    
    @madb.setAttributes([attribute1, attribute2])    
    assert_equal("red", @madb.name1)
    assert_equal(3, @madb.fetch_number2)
  end
  
end

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'rmi'
require 'jmx'


class MyAttributeDynamicBean < RubyDynamicMBean
  rw_attribute :name1, :string, "My sample attribute"
  r_attribute :number1, :int, "My sample integer based attribute that is read only"
  w_attribute :number2, :int, "My sample integer based attribute that is write only"

  def intialize(type, text)
    super(type,text)
  end
  def set_number1(val)
    @number1 = val
  end
  
  def fetch_number2
    @number2
  end
end

class JMXAttributeTest < Test::Unit::TestCase
  
  def setup
    @madb = MyAttributeDynamicBean.new("test.MyTestBean","Mwahahahahahah")    
  end
  
  #make sure we didn't break anything from a ruby perspective
  def test_can_create_bean_and_access_accessor_type_methods
    @madb.set_number1 4
    assert_nil(@madb.name1)
    @madb.name1 = "Name"
    assert_equal("Name", @madb.name1)
    assert_equal(4, @madb.number1)
    @madb.number2 = 4
    assert_equal(4, @madb.fetch_number2)    
    assert_raise(NoMethodError) { @madb.number2 }    
  end

  def test_get_attributes_via_dynamicmbeaninterface
    @madb.set_number1 4
    @madb.name1 = "Name"

    assert_equal(@madb.name1, @madb.getAttribute("name1").get_value.to_s)
    assert_equal(@madb.number1, @madb.getAttribute("number1").get_value)    
    atts = ["name1", "number1"]
    retrieved = @madb.getAttributes(atts)
    assert_equal(2, retrieved.length)
    #TODO: assertion comparing the types in teh array to java types
  end
  
  def test_set_attributes_via_dynamicbeaninterface
    @madb.name1 = "blue"
    red = java.lang.String.new("red")
    attribute = javax.management.Attribute.new("name1", red)
    @madb.setAttribute(attribute)

    assert_equal("String", @madb.name1.class.to_s )
    assert_equal("red", @madb.name1)
  end
  
  def test_set_multiple_attributes_via_dynamicbeaninterface
    @madb.name1 = "blue"
    three = java.lang.Integer.new(3)
    red = java.lang.String.new("red")
    attribute1 = javax.management.Attribute.new("name1", red)
    attribute2 = javax.management.Attribute.new("number2", three)
    
    @madb.setAttributes([attribute1, attribute2])    
    assert_equal("red", @madb.name1)
    assert_equal(3, @madb.fetch_number2)
  end
  
end
