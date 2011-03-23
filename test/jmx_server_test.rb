
$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'rmi'
require 'jmx'

class MyDynamicMBean < RubyDynamicMBean
  rw_attribute :name, :string, "My sample attribute"
  r_attribute :explicit_reader, :int, "Sample int with writer", :my_reader
  w_attribute :explicit_writer, :int, "Sample int with writer", :my_writer
  rw_attribute :explicit_both, :int, "Sample int with writer", :my_read, :my_write

  operation "Doubles a value"
  parameter :int, "a", "Value to double"
  returns :int
  def double(a)
    a + a
  end

  operation "Doubles a string"
  parameter :string, "a", "Value to double" 
  returns :string  
  def string_double(a)
    a + a
  end
  
  operation "Give me foo"
  returns :string
  def foo
    "foo"
  end
  
  operation "Concatentates a list"
  parameter :list, "list", "List to concatenate"
  returns :string
  def concat(list)
    list.inject("") { |memo, element| memo << element.to_s }
  end

  def my_reader
    42
  end

  def my_writer(value)
    @name = value.to_s
  end

  def my_read
    @frogger
  end

  def my_write(value)
    @frogger = value
  end
end

class MyExtendedDynamicMBean < MyDynamicMBean
  operation "Triples a value"
  parameter :int, "a", "Value to triple"
  returns :int
  def triple(a)
    a + a + a
  end
end

class JMXServerTest < Test::Unit::TestCase
  PORT = 9999
  URL = "service:jmx:rmi:///jndi/rmi://localhost:#{PORT}/jmxrmi"
  
  def setup
    @registry = RMIRegistry.new PORT
    @server = JMX::MBeanServer.new
    @connector = JMX::MBeanServerConnector.new(URL, @server)
    @connector.start
    @client = JMX::connect(:port => PORT)
    reg_mbean
  end

  def reg_mbean
    dyna = MyDynamicMBean.new("domain.MySuperBean", "Heh")
    @domain = @server.default_domain
    @server.register_mbean dyna, "#{@domain}:type=MyDynamicMBean"
    @bean = @client["#{@domain}:type=MyDynamicMBean"]
  end

  def unreg_mbean
    @server.unregister_mbean "#{@domain}:type=MyDynamicMBean"
  end

  def teardown
    @connector.stop
    @registry.stop
    unreg_mbean
  end
  
  
  def test_ruby_mbean
    assert_equal("foo", @bean.foo)
    assert_equal(6, @bean.double(3))
    assert_raise(TypeError) { puts @bean.double("HEH") }
    assert_equal("hehheh", @bean.string_double("heh"))
    assert_equal("123", @bean.concat([1,2,3]))
  end

  def test_ruby_mbean_attribtues
    assert_nil(@bean.name)
    @bean.name = "Name"
    assert_equal("Name", @bean.name)

    assert_equal(42, @bean.explicit_reader)
    @bean.explicit_writer = 69
    # explicit_writer changes attribute name as a side-effect
    assert_equal("69", @bean.name)

    @bean.explicit_both = 1
    assert_equal(1, @bean.explicit_both)
  end

  def test_extended_mbean
    dyna = MyExtendedDynamicMBean.new("domain.MySuperBean", "Heh")
    @server.register_mbean dyna, "#{@domain}:type=MyExtendedDynamicMBean"
    @bean = @client["#{@domain}:type=MyExtendedDynamicMBean"]

    assert_equal(12, @bean.triple(4))

    @server.unregister_mbean "#{@domain}:type=MyExtendedDynamicMBean"
  end
end
