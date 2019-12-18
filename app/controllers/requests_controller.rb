class RequestsController < ApplicationController
  def new; end

  def create
    @request = Request.new(params.require(:request).permit(:body))
    @request.save
    redirect_to :requests
  end

  def list
    @requests = Request.all
  end
end
