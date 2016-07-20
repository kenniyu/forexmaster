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

  def create
    size = params[:trade][:size]
    mark = params[:trade][:mark]
    pair = params[:trade][:pair]
    trade = Trade.create_trade(pair, size, mark)
    if trade
      redirect_to action: "index" and return
    else
      redirect_to action: "new" and return
    end
  end

  def history
  end

  private
  def authenticate
    authenticate_or_request_with_http_basic("Administration") do |user,pass|
      user == ENV["USERNAME"] && pass = ENV["PASSWORD"]
    end
  end
end
