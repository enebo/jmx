$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'jmx'

# These tests are for verifying that at a Ruby-level (on server-side) it is still possible 
# to interact with dynamic mbeans as you expect.  *_attributes are backed by ordinary
# Ruby instance variables of the same name.

class MyAttributeDynamicBean < RubyDynamicMBean
  rw_attribute :name, :string, "My sample attribute"
  r_attribute :number_read_only, :int, "My sample integer based attribute that is read only"
  w_attribute :number_write_only, :int, "My sample integer based attribute that is write only"

  # Give us a way to change the attribute for testing
  def set_number_read_only(value)
    @number_read_only = value
  end
  
  def fetch_number_write_only
    @number_write_only
  end
end


class JMXAttributeTest < Test::Unit::TestCase

  def setup
    @madb = MyAttributeDynamicBean.new("test.MyTestBean","Mwahahahahahah")    
  end
  
  #make sure we didn't break anything from a ruby perspective
  def test_can_create_bean_and_access_accessor_type_methods
    @madb.set_number_read_only 4
    assert_nil(@madb.name)
    @madb.name = "Name"
    assert_equal("Name", @madb.name)
    assert_equal(4, @madb.number_read_only)
    @madb.number_write_only = 4
    assert_equal(4, @madb.fetch_number_write_only)    
    assert_raise(NoMethodError) { @madb.number_write_only }    
  end

  def test_get_attributes_via_dynamicmbeaninterface
    @madb.set_number_read_only 4
    @madb.name = "Name"

    assert_equal(@madb.name, @madb.getAttribute("name").get_value.to_s)
    assert_equal(@madb.number_read_only, @madb.getAttribute("number_read_only").get_value)    
    atts = ["name", "number_read_only"]
    retrieved = @madb.getAttributes(atts)
    assert_equal(2, retrieved.length)
    #TODO: assertion comparing the types in teh array to java types
  end
  
  def test_set_attributes_via_dynamicbeaninterface
    @madb.name = "blue"
    red = java.lang.String.new("red")
    attribute = javax.management.Attribute.new("name", red)
    @madb.setAttribute(attribute)

    assert_equal("String", @madb.name.class.to_s )
    assert_equal("red", @madb.name)
  end
  
  def test_set_multiple_attributes_via_dynamicbeaninterface
    @madb.name = "blue"
    three = java.lang.Integer.new(3)
    red = java.lang.String.new("red")
    attribute1 = javax.management.Attribute.new("name", red)
    attribute2 = javax.management.Attribute.new("number_write_only", three)
    
    @madb.setAttributes([attribute1, attribute2])    
    assert_equal("red", @madb.name)
    assert_equal(3, @madb.fetch_number_write_only)
  end
  
end

