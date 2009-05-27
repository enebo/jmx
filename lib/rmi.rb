include Java

java_import java.rmi.registry.LocateRegistry
java_import java.rmi.registry.Registry
java_import java.rmi.server.UnicastRemoteObject

class RMIRegistry
  def initialize(port = Registry::REGISTRY_PORT)
    start(port)
  end

  def start(port)
    @registry = LocateRegistry.createRegistry port

  end

  def stop
    UnicastRemoteObject.unexportObject @registry, true
  end
end

