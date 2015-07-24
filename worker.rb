#!ruby -Ku

require 'pp'
require 'twitter'
require 'tweetstream'
require './db'

class Watch
  def initialize
    @config = YAML.load_file('config.yaml')
    @yaml = YAML.load_file('auth.yaml')

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

    client.track(@config["track_keywords"])
  end

  def on_new_status(status)
    begin
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
        record.created_at = status.created_at

        record.save!
      end

    rescue => e
      # 不明なエラーのときも、とりあえず動き続ける
      puts "#{e} (#{e.class})"
      puts e.backtrace
    end
  end
end

watcher = Watch.new
watcher.start
