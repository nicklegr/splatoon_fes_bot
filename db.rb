require 'mongoid'

class Tweet
  include Mongoid::Document

  field :status_id, type: Integer
  field :text, type: String

  field :user_id, type: Integer
  field :screen_name, type: String
  field :user_name, type: String

  field :created_at, type: Time # Twitterから取得した時刻。not レコード作成時刻

  validates_uniqueness_of :status_id

  index({ status_id: 1 }, { unique: true, name: "status_id_index" })
  index({ created_at: 1 }, { name: "created_at_index" })
end

class User
  include Mongoid::Document

  field :id, type: Integer
  field :name, type: String
  field :screen_name, type: String
end

Mongoid.configure do |config|
  if ENV.key?('MONGODB_PORT_27017_TCP_ADDR')
    # for docker
    config.sessions = { default: { database: 'splatoon_fes', hosts: [ "#{ENV['MONGODB_PORT_27017_TCP_ADDR']}:27017" ] }}
  else
    config.sessions = { default: { database: 'splatoon_fes', hosts: [ 'localhost:27017' ] }}
  end
end

Tweet.create_indexes
