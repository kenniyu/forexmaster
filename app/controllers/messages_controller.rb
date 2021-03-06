require 'houston'

class MessagesController < ApplicationController
  before_filter :authenticate, except: [:index]

  def index
    messages = Message.all.order(created_at: :desc)
    @messages = []

    messages.each do |message|
      @messages << {
        body: message.body,
        date: message.created_at.to_time.to_i
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: @messages }
    end
  end

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

      if params[:push_to_twitter] == "1"
        client = Twitter::REST::Client.new do |config|
          config.consumer_key        = ENV["TWTR_CONSUMER_KEY"]
          config.consumer_secret     = ENV["TWTR_CONSUMER_SECRET"]
          config.access_token        = ENV["TWTR_ACCESS_TOKEN"]
          config.access_token_secret = ENV["TWTR_ACCESS_SECRET"]
        end
        client.update(body)
      end

      redirect_to root_path and return
    else
      redirect_to action: "new" and return
    end
  end

end
