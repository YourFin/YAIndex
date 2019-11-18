class FilesController < ApplicationController
  def list
    render json: Dir.glob("*")
  end
end
