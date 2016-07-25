require 'houston'

class MessagesController < ApplicationController
  before_filter :authenticate

  def new
    @message = Message.new
  end

  def create
    body = params[:message][:body]
    redirect_to action: "new" and return if body.nil? || body.empty?

    @message = Message.create(body: body)
    if @message.save
      apn = Houston::Client.development
      file = File.join(Rails.root, "pems/dev_push.pem")
      if Rails.env.production?
        apn = Houston::Client.production
        file = File.join(Rails.root, "pems/prod_push.pem")
      end

      apn.certificate = File.read(file)

      push_tokens = PushToken.all
      push_tokens.each do |push_token|
        new_badge_count = (push_token.badge || 0) + 1

        # save new badge number
        push_token.badge += 1
        push_token.save

        notification = Houston::Notification.new(device: push_token.token)
        notification.alert = body
        notification.sound = "default"
        notification.badge = new_badge_count
        notification.content_available = true
        apn.push(notification)
      end
      flash[:notice] = "Messages sent"

      redirect_to root_path and return
    else
      redirect_to action: "new" and return
    end
  end

end
