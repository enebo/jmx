$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'rmi'
require 'jmx'

PORT = 9999

class JMXConnectorClientTest < Test::Unit::TestCase
  URL = "service:jmx:rmi:///jndi/rmi://localhost:#{PORT}/jmxrmi"
  
  def setup
    @registry = RMIRegistry.new PORT
    @connector = JMX::MBeanServerConnector.new(URL, JMX::MBeanServer.new)
    @connector.start
    @client = JMX::connect(:port => PORT)
  end
  
  def teardown
    @connector.stop
    @registry.stop
  end

  def test_invalid_mbean_name
    assert_raises(ArgumentError) { @client["::::::"] }
  end
  
  def test_get_mbean
    memory = @client["java.lang:type=Memory"]
    
    assert_not_nil memory, "Could not acquire memory mbean"

    # Attr form
    heap = memory[:HeapMemoryUsage]
    assert_not_nil heap
    assert(heap[:used] > 0, "No heap used?  Impossible!")

    # underscored form
    heap = memory.heap_memory_usage
    assert_not_nil heap
    assert(heap.used > 0, "No heap used?  Impossible!")
  end

  def test_set_mbean
    memory = @client["java.lang:type=Memory"]
    original_verbose = memory.verbose
    memory.verbose = !original_verbose
    assert(memory.verbose != original_verbose, "Could not change verbose")

    memory[:Verbose] = original_verbose
    assert(memory[:Verbose] == original_verbose, "Could not change back verbose")
  end

  def test_attributes
    memory = @client["java.lang:type=Memory"]
    assert(memory.attributes.include?("HeapMemoryUsage"), "HeapMemoryUsage not found")
  end

  def test_operations
    memory = @client["java.lang:type=Memory"]
    assert(memory.operations.include?("gc"), "gc not found")
  end


  def test_simple_operation
    memory = @client["java.lang:type=Memory"]

    heap1 = memory[:HeapMemoryUsage][:used]
    memory.gc
    heap2 = memory[:HeapMemoryUsage][:used]

    assert(heap1.to_i >= heap2.to_i, "GC did not collect")
  end

  def test_simple_operation
    memory = @client["java.lang:type=Memory"]

    heap1 = memory[:HeapMemoryUsage][:used]
    memory.invoke(:gc)
    heap2 = memory[:HeapMemoryUsage][:used]

    assert(heap1.to_i >= heap2.to_i, "GC did not collect")
  end
  
  def test_query_names
    names = @client.query_names("java.lang:type=MemoryPool,*")
    assert(names.size > 0, "No memory pools. Impossible!")
   
    a_memory_pool_bean = @client[names.to_array[0]]
    assert_not_nil a_memory_pool_bean, "Name must resolve to something"

    usage = a_memory_pool_bean[:Usage]
    assert_not_nil usage, "Memory pools have usage"
    
    assert_not_nil usage[:used], "Some memory is used"
  end
end
