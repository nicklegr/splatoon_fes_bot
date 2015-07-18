require 'mongoid'

class Tweet
  include Mongoid::Document

  field :status_id, type: Integer
  field :text, type: String

  field :user_id, type: Integer
  field :screen_name, type: String
  field :user_name, type: String
  # field :profile_image_url, type: String

  # @todo in_reply_to, mentionの宛先も保存

  field :urls, type: Array
  
  field :source, type: String # 削除ツイートの発信場所の証拠になるかもしれない

  field :retweet_count, type: Integer
  field :created_at, type: Time # Twitterから取得した時刻。not レコード作成時刻

  validates_uniqueness_of :status_id

  index({ status_id: 1 }, { unique: true, name: "status_id_index" })
  index({ created_at: 1 }, { name: "created_at_index" })
end

class Deleted
  include Mongoid::Document

  field :user_id, type: Integer
  field :status_id, type: Integer
  field :deleted_at, type: Time

  index({ deleted_at: 1 }, { name: "deleted_at_index" })
end

class Target
  include Mongoid::Document

  embeds_many :users
end

class User
  include Mongoid::Document

  field :id, type: Integer
  field :name, type: String
  field :screen_name, type: String
  field :location, type: String
  field :description, type: String
  field :url, type: String
  field :time_zone, type: String
  field :created_at, type: Time
  field :profile_image_url, type: String
  field :friends_count, type: Integer
  field :followers_count, type: Integer
  field :favourites_count, type: Integer
  field :statuses_count, type: Integer

  embedded_in :target
end

Mongoid.configure do |config|
  if ENV.key?('MONGODB_PORT_27017_TCP_ADDR')
    # for docker
    config.sessions = { default: { database: 'darkmatter', hosts: [ "#{ENV['MONGODB_PORT_27017_TCP_ADDR']}:27017" ] }}
  else
    config.sessions = { default: { database: 'darkmatter', hosts: [ 'localhost:27017' ] }}
  end
end

Tweet.create_indexes
Deleted.create_indexes
