#!ruby -Ku

require 'pp'
require 'twitter'
require 'tweetstream'
require './db'

class Watch
  def initialize
    @yaml = YAML.load_file('config.yaml')

    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key = @yaml['consumer_key']
      config.consumer_secret = @yaml['consumer_secret']
      config.access_token = @yaml['oauth_token']
      config.access_token_secret = @yaml['oauth_token_secret']
    end

    TweetStream.configure do |config|
      config.consumer_key = @yaml['consumer_key']
      config.consumer_secret = @yaml['consumer_secret']
      config.oauth_token = @yaml['oauth_token']
      config.oauth_token_secret = @yaml['oauth_token_secret']
      config.auth_method = :oauth
    end
  end

  def start
    client = TweetStream::Client.new

    client.on_timeline_status do |status|
      on_new_status(status)
    end

    client.on_delete do |status_id, user_id|
      on_delete(status_id, user_id)
    end

    target_ids = @twitter.users(@yaml['target_users']).map do |e|
      e.id
    end

    client.follow(target_ids)
  end

  def on_new_status(status)
    begin
      # followは、その人への in-reply-to や retweet も飛んでくる
      # reply-toは宝がありそうだけど、RTは捨てる
      return if status.retweeted_status?

      puts "#{status.user.id} #{status.user.screen_name} #{status.text}"
      # pp status

      # オリジナルを作成 or 探す
      record = Tweet.find_or_initialize_by(status_id: status.id)
      if record.new_record?
        record.status_id = status.id
        record.text = status.text
        record.user_id = status.user.id
        record.screen_name = status.user.screen_name
        record.user_name = status.user.name
        # record.profile_image_url = status.user.profile_image_url

        if status.urls.size != 0
          record.urls = status.urls.map do |e| e.expanded_url.to_s end
        end

        record.source = status.source
        record.retweet_count = status.retweet_count
        record.created_at = status.created_at

        record.save!
      end

    rescue => e
      # 不明なエラーのときも、とりあえず動き続ける
      puts "#{e} (#{e.class})"
      puts e.backtrace
    end
  end

  def on_delete(status_id, user_id)
    # puts "deleted: #{user_id}'s #{status_id}"
    
    record = Deleted.find_or_initialize_by(status_id: status_id)
    if record.new_record?
      record.user_id = user_id
      record.status_id = status_id
      record.deleted_at = Time.now

      record.save!
    end
  end
end

watcher = Watch.new
watcher.start
