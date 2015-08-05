# coding: utf-8

require "clockwork"
require "twitter"
require "pp"
require_relative "stat"

class Bot
  def initialize
    config = YAML.load_file('config.yaml')
    @start_time = Time.parse(config['fes_period']['start'])
    @end_time = Time.parse(config['fes_period']['end'])

    @yaml = YAML.load_file('auth.yaml')

    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key = @yaml['consumer_key']
      config.consumer_secret = @yaml['consumer_secret']
      config.access_token = @yaml['oauth_token']
      config.access_token_secret = @yaml['oauth_token_secret']
    end
  end

  def tweet
    # 開催時間外はツイートしない
    # 開始・終了時刻ちょうどはツイートしたいのでマージン
    return if Time.now < (@start_time - 1.minute) || (@end_time + 1.minute) < Time.now

    stat = Stat.new.get

    tweet = sprintf(<<-EOS, stat[:rate_a], stat[:rate_b], stat[:rate_undecided])
【選挙速報】
#{stat[:team_a_name]} %.1f%%
#{stat[:team_b_name]} %.1f%%
中立 %.1f%%

#{stat[:winner]}が優勢です！

(集計アカウント数: #{stat[:total_vote]})
#splatoon #スプラトゥーン
    EOS

    @twitter.update(tweet)

    # log
    puts Time.now
    puts "total_vote: #{stat[:total_vote]} votes_a: #{stat[:votes_a]} votes_b: #{stat[:votes_b]} votes_undecided: #{stat[:votes_undecided]}"
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
