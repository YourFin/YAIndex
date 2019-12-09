class WebAppController < ApplicationController
  def main
    render :template => "web_app/main.html.erb"
  end

  protected

  def set_default_response_format
    request.format = :html
  end
end
