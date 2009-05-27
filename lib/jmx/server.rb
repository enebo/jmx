module JMX
  # The MBeanServer represents a connection to an MBean server
  # rather than an actual MBean server.  Depending upon how 
  # this object is constructed you can either talk to the 
  # PlatformMBeanServer or any "remote" MBean server.
  #--
  # Represents both MBeanServer and MBeanServerConnection
  #++ 
  class MBeanServer
    java_import javax.management.Attribute
    java_import javax.management.MBeanServerFactory
    java_import javax.management.remote.JMXConnectorFactory
    java_import javax.management.remote.JMXServiceURL

    attr_accessor :server
    @@classes = {}

    # when creatinga  new MBeanServer you can optionally specify a location, username, and password
    # if specify these values (or at least the location) the MBeanServer instance will connect to 
    # an existing (and remote ) MBean server and register the mbeans there.
    # otherwise the server will connect to to the local Platform MBean Server.
    def initialize(location=nil, username=nil, password=nil)
      if (location)
        env = username ? 
          {"jmx.remote.credentials" => [username, password].to_java(:string)} :
          nil
        url = JMXServiceURL.new location
        @server = JMXConnectorFactory.connect(url, env).getMBeanServerConnection
      else
        @server = java.lang.management.ManagementFactory.getPlatformMBeanServer
        #@server = MBeanServerFactory.createMBeanServer
      end
    end

    def [](object_name)
      name = make_object_name object_name

      unless @server.isRegistered(name)
        raise NoSuchBeanError.new("No name: #{object_name}") 
      end

      #### TODO: Why?
      @server.getObjectInstance name
      MBeanProxy.generate(@server, name)
    end

    def []=(class_name, object_name)
      name = make_object_name object_name

      @server.createMBean class_name, name, nil, nil

      MBeanProxy.generate(@server, name)
    end

    def default_domain
      @server.getDefaultDomain
    end

    def domains
      @server.domains
    end

    def mbean_count
      @server.getMBeanCount
    end

    def query_names(name=nil, query=nil)
      object_name = name.nil? ? nil : make_object_name(name)

      @server.query_names(object_name, query)
    end
    
    def unregister_mbean(object_name)
      name = make_object_name object_name
      @server.unregisterMBean(name)
      
    end

    def register_mbean(object, object_name)
      name = make_object_name object_name
      @server.registerMBean(object, name)
      MBeanProxy.generate(@server, name)
    end
    
    def self.find(agent_id=nil)
      MBeanServerFactory.findMBeanServer(agent_id)
    end

    private

    def make_object_name(object_name)
      return object_name if object_name.kind_of? ObjectName

      ObjectName.new object_name
    rescue
      raise ArgumentError.new("Invalid ObjectName #{$!.message}")
    end
  end

  class NoSuchBeanError < RuntimeError
  end

  class MBeanServerConnector
    java_import javax.management.remote.JMXServiceURL
    java_import javax.management.remote.JMXConnectorServerFactory

    def initialize(location, server)
      @url = JMXServiceURL.new location
      @server = JMXConnectorServerFactory.newJMXConnectorServer @url, nil, server.server

      if block_given?
	start
        yield
        stop
      end
    end

    def active?
      @server.isActive
    end

    def start
      @server.start
      self
    end

    def stop
      @server.stop if active?
    end
  end
end
