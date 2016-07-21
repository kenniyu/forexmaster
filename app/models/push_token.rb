class PushToken < ActiveRecord::Base
  validates_uniqueness_of :token
end
