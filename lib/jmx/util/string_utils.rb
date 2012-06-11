module JMX
  module StringUtils
    def snakecase(string)
      string.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    def camelcase(string)
      if string =~ /_/
        string.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        string.to_s
      end
    end
  end
end
