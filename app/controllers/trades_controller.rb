require 'houston'

class TradesController < ApplicationController
  before_filter :authenticate, only: [:new, :create]

  def index
    @portfolio = Trade.open_positions
    respond_to do |format|
      format.html
      format.json { render json: @portfolio }
    end
  end

  def new
    @trade = Trade.new
  end

  def performance
    from_date = params[:from_date]
    to_date = params[:to_date]

    if !from_date
      from_date = Date.strptime('01-01-2016', '%m-%d-%Y')
    else
      from_date = Date.strptime(from_date, '%m-%d-%Y')
    end

    if !to_date
      to_date = Date.tomorrow
    else
      to_date = Date.strptime(from_date, '%m-%d-%Y') + 1
    end

    @trade_hash = Trade.pnl(from_date, to_date)
    
    respond_to do |format|
      format.html
      format.json { render json: @trade_hash }
    end
  end

  def create
    size = params[:trade][:size]
    mark = params[:trade][:mark]
    pair = params[:trade][:pair]
    trade = Trade.create_trade(pair, size, mark)
    if trade
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
        notification.alert = "New trade available!"
        notification.sound = "default"
        notification.badge = new_badge_count
        notification.content_available = true
        apn.push(notification)
      end

      redirect_to action: "index" and return
    else
      redirect_to action: "new" and return
    end
  end

  def history
    @trades = Trade.history
    respond_to do |format|
      format.html
      format.json { render json: @trades }
    end
  end

end
