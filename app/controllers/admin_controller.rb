class AdminController < ApplicationController
  before_filter :authenticate

  def index
    @push_tokens = PushToken.all
  end
end
