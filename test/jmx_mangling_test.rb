$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'jmx'

class JMXConnectorClientTest < Test::Unit::TestCase
  def test_that_mbeans_parent_for_handles_classes_with_dollar_sign
    bean_module, class_name = JMX::MBeans.parent_for("evil.dollar.Pre$Middle$Post")
    assert_equal(JMX::MBeans::Evil::Dollar, bean_module)
    assert_equal("PreDollarMiddleDollarPost", class_name)
  end

  def test_mbeans_parent_for
    bean_module, class_name = JMX::MBeans.parent_for("com.example.JavaClass")
    assert_equal(JMX::MBeans::Com::Example, bean_module)
    assert_equal("JavaClass", class_name)
  end
end
