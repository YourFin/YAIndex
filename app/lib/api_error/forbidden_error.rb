module ApiError
  class ForbiddenError < ApiError::BaseApiError
    def initialize(message = "Forbidden.")
      super(403, message)
    end
  end
end
