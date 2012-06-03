module JMX
  module RubyNotificationEmitter
    java_import javax.management.MBeanNotificationInfo

    include javax.management.NotificationEmitter

    def listeners
      @listener ||= {}
    end

    # NotificationListener listener, NotificationFilter filter, Object handback
    def addNotificationListener(listener, filter, handback)
      listeners[listener] = [filter, handback]
    end

    def getNotificationInfo
      [].to_java MBeanNotificationInfo
    end

    # NotificationListener listener, NotificationFilter filter, Object handback
    def removeNotificationListener(listener, filter=nil, handback=nil)
      found = false
      listeners.delete_if do |clistener, (cfilter, chandback)|
        v = listener == clistener && filter == cfilter && handback == chandback
        found = true if v
        v
      end
      raise javax.management.ListenerNotFoundException.new unless found
    end
  end
end
