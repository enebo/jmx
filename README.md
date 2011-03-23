= JMX

== DESCRIPTION:

JMX is a library which allows you to access JMX MBeans as a client or create
your own MBeans as a Ruby class.

http://jruby-extras.rubyforge.org/jmx/

== FEATURES/PROBLEMS:

* Use '-J-Dcom.sun.management.jmxremote' to make jruby process accessible from a jruby command-line

== SYNOPSIS:

require 'jmx'

client = JMX.simple_connect(:port => 9999)

memory = client["java.lang:type=Memory"]
puts memory.attributes

== REQUIREMENTS:

* JRuby

== INSTALL:

* jruby -S gem install jmx
