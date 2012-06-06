require 'java'

java_import java.util.ArrayList

module JMX
  ##
  # Create a Ruby proxy based on the MBean represented by the object_name
  # This proxy will be able to dispatch to the actual MBean to allow it to
  # execute operations and read/update attributes.  The primary mechanism
  # for calling attributes or operations is to just call them as if they 
  # represented methods on the MBean.   For example:
  # 
  #    memory = client["java.lang:type=Memory"]
  #    memory.gc
  #    memory.heap_memory_usage.used
  #
  # Here we first call an operation on this Memory heap called 'gc' and then
  # we access an attribute 'heap_memory_usage' (Note: we can use snake-cased
  # naming instead of actual 'HeapMemoryUsage').  In the case of a naming 
  # conflict (existing Ruby method, or same-named attribute as MBean operation),
  # there there are long hand mechanisms:
  #
  #    memory = client["java.lang:type=Memory"]
  #    memory.invoke(:gc)
  #    memory[:heap_memory_usage][:used]
  #
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

    ##
    # Get MBean attribute specified by name.  If it is just a plain attribute 
    # then unwrap the attribute and just return the value.
    def [](name)
      attribute = @server.getAttribute(@object_name, name.to_s)
      return attribute.value if attribute.kind_of? javax.management.Attribute
      attribute
    end

    ##
    # Set MBean attribute specified by name to value
    def []=(name, value) 
      @server.setAttribute @object_name, javax.management.Attribute.new(name.to_s, value)
    end

    ##
    # Invoke an operation.  A NoMethodError will be thrown if this MBean
    # cannot respond to the operation.
    #
    # FIXME: Add scoring to pick best match instead of first found
    def invoke(name, *params)
      op = @info.operations.find { |o| o.name == name.to_s }
      
      raise NoMethodError.new("No such operation #{name}") unless op

      jargs, jtypes = java_args(op.signature, params)
      @server.invoke @object_name, op.name, jargs, jtypes
    end

    def add_notification_listener(filter=nil, handback=nil, &listener)
      @server.addNotificationListener @object_name, listener, filter, handback
    end

    def remove_notification_listener(listener)
      @server.removeNotificationListener @object_name, listener
    end

    private

    # Define ruby friendly methods for attributes.  For odd attribute names or
    # names that you want to call with the actual attribute name you can call 
    # aref/aset ([], []=).
    def define_attributes
      @info.attributes.each do |attr|
        rname = underscore(attr.name)
        self.class.__send__(:define_method, rname) { self[attr.name] } if attr.readable?
        self.class.__send__(:define_method, rname + "=") {|v| self[attr.name] = v } if attr.writable?
      end
    end

    # Define ruby friendly methods for operations.  For name conflicts you
    # should call 'invoke(op_name, *args)'
    def define_operations
      @info.operations.each do |op| 
        self.class.__send__(:define_method, op.name) do |*params|
          jargs, jtypes = java_args(op.signature, params)
          @server.invoke @object_name, op.name, jargs, jtypes
        end
      end
    end

    # Given the signature and the parameters supplied do these signatures match.
    # Repackage these parameters as Java objects in a primitive object array.
    def java_args(signature, params)
      return nil if params.nil?

      jtypes = []
      jargs = []
      params.each_with_index do |param, i|
        type = signature[i].get_type
        jtypes << type
        required_type = JavaClass.for_name(type)
        
        java_arg = param.to_java(:object)
        java_arg = param.to_java(Java::java.lang.Integer) if required_type.name == "int"
        java_arg = param.to_java(Java::java.lang.Short) if required_type.name == "short"
        java_arg = param.to_java(Java::java.lang.Float) if required_type.name == "float"

        if (param.kind_of? Array)
          java_arg = param.inject(ArrayList.new) {|l, element| l << element }
        end
        
        jargs << java_arg

        arg_type = java_arg.java_class
        
        raise TypeError.new("parameter #{signature[i].name} expected to be #{required_type}, but was #{arg_type}") if !required_type.assignable_from? arg_type
      end
      [jargs.to_java, jtypes.to_java(:string)]
    end

    # Convert a collection of java objects to their Java class name equivalents
    def java_types(params)
      return nil if params.nil?

      params.map {|e| e.class.java_class.name }.to_java(:string)
    end

    def underscore(string)
      string.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end
  end
end
