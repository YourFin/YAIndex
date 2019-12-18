class RequestsController < ApplicationController
  def new; end

  def create
    render plain: params[:request].inspect
  end

  def list; end
end
