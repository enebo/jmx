$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'jmx'

class MyNotificationDynamicBean < RubyDynamicMBean
  rw_attribute :number, :int, "My sample integer based attribute that is write only"

  attribute_change_notification "Number Changed", :number
end


class JMXAttributeTest < Test::Unit::TestCase

  def setup
    @madb = MyNotificationDynamicBean.new("test.MyTestBean","Mwahahahahahah")    
  end
  
  def test_can_get_notifications_on_change
    @madb.number = 1
    assert_equal("Name", @madb.name1)
    assert_equal(4, @madb.number1)
    @madb.number2 = 4
    assert_equal(4, @madb.fetch_number2)    
    assert_raise(NoMethodError) { @madb.number2 }    
  end
end

