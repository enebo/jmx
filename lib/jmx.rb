include Java

require 'rmi'
require 'jmx/dynamic_mbean'
require 'jmx/server'
require 'jmx/object_name'
require 'jmx/composite_data'
require 'jmx/mbean_proxy'
require 'jmx/mbeans'

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
    server = opts[:server] || JMX::MBeanServer.new
    url = "service:jmx:rmi:///jndi/rmi://localhost:#{port}#{url_path}"
    $registry = opts[:registry] || RMIRegistry.new(port)
    @connector = JMX::MBeanServerConnector.new(url, JMX::MBeanServer.new).start
  end
end
