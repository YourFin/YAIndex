class ApiController < ApplicationController
  rescue_from ApiError::BaseApiError, :with => :render_error_resoponse

  def render_error_resoponse(error)
    render json: error.retrieve_hash, status: error.http_code
  end
end
