# coding: utf-8

require "clockwork"
require "twitter"
require "pp"
require_relative "stat"

class Bot
  def initialize
    @yaml = YAML.load_file('auth.yaml')

    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key = @yaml['consumer_key']
      config.consumer_secret = @yaml['consumer_secret']
      config.access_token = @yaml['oauth_token']
      config.access_token_secret = @yaml['oauth_token_secret']
    end
  end

  def tweet
    stat = Stat.get

    tweet = sprintf(<<-EOS, stat[:rate_a], stat[:rate_b])
【選挙速報】
#{stat[:team_a_name]} %.1f%%
#{stat[:team_b_name]} %.1f%%

#{stat[:winner]}が優勢です！

(集計アカウント数: #{stat[:total_vote]})
#splatoon #スプラトゥーン
    EOS

    @twitter.update(tweet)

    # log
    puts Time.now
    puts "total_vote: #{stat[:total_vote]} votes_a: #{stat[:votes_a]} votes_b: #{stat[:votes_b]}"
    puts tweet
  end
end

module Clockwork
  def self.tweet
    bot = Bot.new
    bot.tweet
  end

  handler do |job|
    self.send(job.to_sym)
  end

  every(1.hour, "tweet", :at => "**:00")
end
