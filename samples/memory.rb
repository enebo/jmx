require 'jmx'

def in_mb(value)
  format "%0.2f Mb" % (value.to_f / (1024 * 1024))
end

server = JMX.simple_server
client = JMX.connect
memory = client["java.lang:type=Memory"]

Thread.new do
  puts "Enter 'gc' to garbage collect or anything else to quit"
  while (command = gets.chomp)
    break if command != "gc"
    memory.gc
  end

  server.stop
  exit 0
end

while (true)
  heap = in_mb(memory.heap_memory_usage.used)
  non_heap = in_mb(memory.non_heap_memory_usage.used)

  puts "Heap: #{heap}, Non-Heap: #{non_heap}"
  sleep(2)
end

