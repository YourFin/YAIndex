module ApiError
  class BaseApiError < StandardError
    attr_reader :http_code, :type, :message

    def initialize(http_code, message)
      @type = self.class.name.scan(/ApiError::(.*)/).flatten.first
      @http_code = http_code
      @message = message
    end

    def retrieve_hash
      { :error => @type, :message => @message }
    end
  end
end
