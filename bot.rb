# coding: utf-8

require "twitter"
require "pp"
require_relative "db"

TEAM_A_WORDS = %w|
  レモン
  アオリ
|

TEAM_B_WORDS = %w|
  ミルク
  ホタル
|

class Bot
  def initialize
    @yaml = YAML.load_file('config.yaml')

    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key = @yaml['consumer_key']
      config.consumer_secret = @yaml['consumer_secret']
      config.access_token = @yaml['oauth_token']
      config.access_token_secret = @yaml['oauth_token_secret']
    end

    @votes = count_vote()
  end

  def start
    votes_a, votes_b = @votes
    total_vote = votes_a + votes_b
    rate_a = 100.0 * votes_a / total_vote
    rate_b = 100.0 * votes_b / total_vote

    puts sprintf("【選挙速報】\nレモンティー %.1f%%\nミルクティー %.1f%%\n(集計対象 %d人)",
      rate_a, rate_b, total_vote)
  end

  def count_vote
    found_tweets = Tweet.all.select do |e|
      ret = false
      (TEAM_A_WORDS + TEAM_B_WORDS).each do |word|
        if e.text.include?(word)
          ret = true
          break
        end
      end
      ret
    end

    user_tweets = found_tweets.group_by do |e|
      e.user_id
    end

    votes_a = votes_b = 0

    user_tweets.each do |user_id, tweets|
      score_a = score_b = 0

      tweets.each do |tweet|
        TEAM_A_WORDS.each do |e|
          score_a += tweet.text.scan(e).size
        end

        TEAM_B_WORDS.each do |e|
          score_b += tweet.text.scan(e).size
        end
      end

      if score_a > score_b
        votes_a += 1
      elsif score_b > score_a
        votes_b += 1
      end

      # debug
      tweets << {
        "score_a" => score_a,
        "score_b" => score_b,
      }
    end

    # debug
    pp user_tweets

    [ votes_a, votes_b ]
  end
end

bot = Bot.new
bot.start
