class PushTokenController < ApplicationController
  skip_before_filter  :verify_authenticity_token

  def register_token
    puts token
    token = params[:token]
    return if token.nil?

    push_token = PushToken.create(token: token)
    @success = push_token.save

    respond_to do |format|
      format.html
      format.json { render json: @success }
    end
  end
end
