# JMX

## DESCRIPTION:

JMX is a library which allows you to access JMX MBeans as a client or create
your own MBeans as a Ruby class.

## SYNOPSIS:

Connect to same JVM as client script and look at Memory MBean

```ruby
   require 'jmx'

   client = JMX.connect(:host => 'localhost', :port => 9999)

   memory = client["java.lang:type=Memory"]
   puts memory.attributes
```

You can also create your own MBeans and register them as well:

```ruby
   require 'jmx'

   class MyDynamicMBean < RubyDynamicMBean
     rw_attribute :name, :string, "My sample attribute"
     r_attribute :explicit_reader, :int, "Sample int with writer", :my_reader

     operation "Doubles a value"
     parameter :int, "a", "Value to double"
     returns :int
     def double(a)
       a + a
     end
   end

   my_server = JMX::MBeanServer.new
   my_server_connector = JMX.simple_server(server: my_server)

   dyna = MyDynamicMBean.new("domain.MySuperBean", "Heh")
   domain = my_server.default_domain
   my_server.register_mbean dyna, "#{domain}:type=MyDynamicMBean"
```

## REQUIREMENTS:

* JRuby

## INSTALL:

* jruby -S gem install jmx

## PROBLEMS:

* Use '-J-Dcom.sun.management.jmxremote' to make jruby process accessible from a jruby command-line

