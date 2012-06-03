require 'java'

module JMX
  # Holder for beans created from retrieval (namespace protection [tm]).
  # This also gives MBeans nicer names when inspected
  module MBeans
    ##
    # Create modules in this namespace for each package in the Java fully
    # qualified name and return the deepest module along with the Java class
    # name back to the caller.
    def self.parent_for(java_class_fqn)
      java_class_fqn.split(".").inject(MBeans) do |parent, segment|
        # const_defined? will crash later if we don't remove $
        segment.gsub!('$', 'Dollar') if segment =~ /\$/
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
end
