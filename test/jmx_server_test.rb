# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'rmi'
require 'jmx'

class MyDynamicMBean < RubyDynamicMBean
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
  end
  
  def teardown
    @connector.stop
    @registry.stop
  end
  
  def test_ruby_mbean
    dyna = MyDynamicMBean.new("domain.MySuperBean", "Heh")
    domain = @server.default_domain
    @server.register_mbean dyna, "#{domain}:type=MyDynamicMBean"
    
    # Get bean from client connector connection
    bean = @client["#{domain}:type=MyDynamicMBean"]
    assert_equal("foo", bean.foo)
    assert_equal(6, bean.double(3))
    assert_raise(TypeError) { puts bean.double("HEH") }
    assert_equal("hehheh", bean.string_double("heh"))
    assert_equal("123", bean.concat([1,2,3]))
  end
  def test_ruby_mbean_twice
    dyna = MyDynamicMBean.new("domain.MySuperBean", "Heh")
    domain = @server.default_domain
    @server.unregister_mbean "#{domain}:type=MyDynamicMBean"
    @server.register_mbean dyna, "#{domain}:type=MyDynamicMBean"        
    # Get bean from client connector connection
    bean = @client["#{domain}:type=MyDynamicMBean"]
    assert_equal("foo", bean.foo)
    assert_equal(6, bean.double(3))
    assert_raise(TypeError) { puts bean.double("HEH") }
    assert_equal("hehheh", bean.string_double("heh"))
    assert_equal("123", bean.concat([1,2,3]))
  end
end
