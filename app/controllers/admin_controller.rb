require 'gmail'
require 'houston'

class AdminController < ApplicationController
  before_filter :authenticate

  def index
  end

  def devices
    @push_tokens = PushToken.all
  end

  def messages
    @messages = Message.all.order(created_at: :desc)
  end

  def push
    push_target = params[:push_target]
    body = params[:body]
    body = body.gsub("#", "")

    @success = false

    if push_target == "app"
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
      flash[:notice] = "Push notification sent"

      # save the message
      @message = Message.create!(body: body)

      @success = true
    elsif push_target == "twitter"
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["TWTR_CONSUMER_KEY"]
        config.consumer_secret     = ENV["TWTR_CONSUMER_SECRET"]
        config.access_token        = ENV["TWTR_ACCESS_TOKEN"]
        config.access_token_secret = ENV["TWTR_ACCESS_SECRET"]
      end
      client.update(body)
      @success = true
    else
      puts "Push target not defined."
    end
  end

  def trades
    @trades = []
    puts ENV["GMAIL_USERNAME"]

    Gmail.new(ENV["GMAIL_USERNAME"], ENV["GMAIL_PASSWORD"]) do |gmail|
      tos_from = "alerts@thinkorswim.com"
      tos_mails = gmail.inbox.find(:from => tos_from).last(10)
      tos_mails.each do |mail|
        body = mail.body.raw_source
        if body.include? "# @"
          account_substr = body.slice(0..body.rindex(", ACCOUNT") - 1)
          start_index = body.index("tIP ")
          tip_substr = account_substr[start_index + 4..-1]
          puts tip_substr
          @trades << tip_substr
        end
      end
    end
  end
end
