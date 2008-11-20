include Java

require 'rmi'
require 'jmx/dynamic_mbean'
require 'jmx/server'

import java.util.ArrayList
import javax.management.Attribute
import javax.management.MBeanInfo
import javax.management.DynamicMBean

module JMX
  import javax.management.ObjectName
  class ObjectName
    def [](key)
      get_key_property(key.to_s)
    end
  
    def info(server)
      server.getMBeanInfo(self)
    end
  end
end

module javax::management::openmbean::CompositeData
  include Enumerable

  def [](key)
    get(key.to_s)
  end

  def method_missing(name, *args)
    self[name]
  end

  def each
    get_composite_type.key_set.each { |key| yield key }
  end

  def each_pair
    get_composite_type.key_set.each { |key| yield key, get(key) }
  end
end

module JMX
  ##
  # Connect to a MBeanServer
  # opts can contain several values
  #   :host - The hostname where the server resides (def: localhost)
  #   :port - Which port the server resides at (def: 8686)
  #   :url_path - path part of JMXServerURL (def: /jmxrmi)
  #   :user - User to connect as (optional)
  #   :password - Password for user (optional)
  def self.connect(opts = {})
    host = opts[:host] || 'localhost'
    port = opts[:port] || 8686
    url_path = opts[:url_path] || "/jmxrmi"
    url = "service:jmx:rmi:///jndi/rmi://#{host}:#{port}#{url_path}"

    if opts[:user]
      JMX::MBeanServer.new url, opts[:user], opts[:password]
    else
      JMX::MBeanServer.new url
    end
  end

  ##
  # sad little simple server setup so you can connect up to it.
  # 
  def self.simple_server(opts = {})
    port = opts[:port] || 8686
    url_path = opts[:url_path] || "/jmxrmi"
    url = "service:jmx:rmi:///jndi/rmi://localhost:#{port}#{url_path}"
    $registry = RMIRegistry.new port
    @connector = JMX::MBeanServerConnector.new(url, JMX::MBeanServer.new).start
  end

  # Holder for beans created from retrieval (namespace protection [tm]).
  # This also gives MBeans nicer names when inspected
  module MBeans
    ##
    # Create modules in this namespace for each package in the Java fully
    # qualified name and return the deepest module along with the Java class
    # name back to the caller.
    def self.parent_for(java_class_fqn)
      java_class_fqn.split(".").inject(MBeans) do |parent, segment|
        # Note: We are boned if java class name is lower cased
        return [parent, segment] if segment =~ /^[A-Z]/

        segment.capitalize!
        unless parent.const_defined? segment
          parent.const_set segment, Module.new
        else 
          parent.const_get segment
        end
      end

    end
  end

  # Create a Ruby proxy based on the MBean represented by the object_name
  class MBeanProxy
    # Generate a friendly Ruby proxy for the MBean represented by object_name
    def self.generate(server, object_name)
      parent, class_name = MBeans.parent_for object_name.info(server).class_name

      if parent.const_defined? class_name
        proxy = parent.const_get(class_name)
      else
        proxy = Class.new MBeanProxy
        parent.const_set class_name, proxy
      end

      proxy.new(server, object_name)
    end

    def initialize(server, object_name)
      @server, @object_name = server, object_name
      @info = @server.getMBeanInfo(@object_name)

      define_attributes
      define_operations
    end

    def attributes
      @attributes ||= @info.attributes.inject([]) { |s,attr| s << attr.name }
    end

    def operations
      @operations ||= @info.operations.inject([]) { |s,op| s << op.name }
    end

    # Get MBean attribute specified by name
    def [](name)
      @server.getAttribute @object_name, name.to_s
    end

    # Set MBean attribute specified by name to value
    def []=(name, value) 
      @server.setAttribute @object_name, javax.management.Attribute.new(name.to_s, value)
    end

    def add_notification_listener(filter=nil, handback=nil, &listener)
      @server.addNotificationListener @object_name, listener, filter, handback
    end

    def remove_notification_listener(listener)
      @server.removeNotificationListener @object_name, listener
    end

    def method_missing(name, *args)
      puts "Invoking: #{name}, #{args}"
      java_args = java_args(args)
      @server.invoke @object_name, name.to_s, java_args, java_types(java_args)
    end

    private

    # Define ruby friendly methods for attributes.  For odd attribute names or names
    # that you want to call with the actual attribute name you can call aref/aset
    def define_attributes
      @info.attributes.each do |attr|
        rname = underscore(attr.name)
        self.class.__send__(:define_method, rname) { self[attr.name] } if attr.readable?
        self.class.__send__(:define_method, rname + "=") {|v| self[attr.name] = v } if attr.writable?
      end
    end

    def define_operations
      @info.operations.each do |op| 
        self.class.__send__(:define_method, op.name) do |*args|
          jargs = java_args(op.signature, args)
          @server.invoke @object_name, op.name, jargs, java_types(jargs)
        end
      end
    end

    # Given the signature and the parameters supplied do these signatures match.
    # Repackage these parameters as Java objects in a primitive object array.
    def java_args(signature, params)
      return nil if params.nil?

      i = 0
      params.map do |param|
        required_type = JavaClass.for_name(signature[i].get_type)
        java_arg = Java.ruby_to_java(param)

        if (param.kind_of? Array)
          java_arg = param.inject(ArrayList.new) {|l, element| l << element }
        end

        arg_type = java_arg.java_class
        
        raise TypeError.new("parameter #{signature[i].name} expected to be #{required_type}, but was #{arg_type}") if !required_type.assignable_from? arg_type
        i = i + 1
        
        java_arg
      end.to_java(:object)
    end

    # Convert a collection of java objects to their Java class name equivalents
    def java_types(params)
      return nil if params.nil?

      params.map {|e| params.java_class.name }.to_java(:string)
    end

    def underscore(string)
      string.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end
  end
end
