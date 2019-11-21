module ApiError
  class UnauthoriedError < ApiError::BaseApiError
    def initialize(message = "Access denied.")
      super(401, message)
    end
  end
end
