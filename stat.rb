# coding: utf-8

require_relative "db"

TEAM_A_NAME = "レモンティー"
TEAM_B_NAME = "ミルクティー"

TEAM_A_WORDS = %w|
  レモン
  アオリ
|

TEAM_B_WORDS = %w|
  ミルク
  ホタル
|

class Stat
  def self.get(team_a_words=TEAM_A_WORDS, team_b_words=TEAM_B_WORDS)
    votes_a, votes_b = count_vote(team_a_words, team_b_words)
    total_vote = votes_a + votes_b

    {
      :team_a_name => TEAM_A_NAME,
      :team_b_name => TEAM_B_NAME,
      :votes_a => votes_a,
      :votes_b => votes_b,
      :total_vote => total_vote,
      :rate_a => 100.0 * votes_a / total_vote,
      :rate_b => 100.0 * votes_b / total_vote,
      :winner => votes_a > votes_b ? TEAM_A_NAME : TEAM_B_NAME,
    }
  end

  def self.count_vote(team_a_words, team_b_words)
    config = YAML.load_file('config.yaml')
    @start_time = Time.parse(config['fes_period']['start'])
    @end_time = Time.parse(config['fes_period']['end'])

    valid_tweets = Tweet
      .where(:created_at.gte => @start_time)
      .and(:created_at.lte => @end_time)

    found_tweets = valid_tweets.select do |e|
      ret = false
      (team_a_words + team_b_words).each do |word|
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
        team_a_words.each do |e|
          score_a += tweet.text.scan(e).size
        end

        team_b_words.each do |e|
          score_b += tweet.text.scan(e).size
        end
      end

      if score_a > score_b
        votes_a += 1
      elsif score_b > score_a
        votes_b += 1
      end

      # debug
      # tweets << {
      #   "score_a" => score_a,
      #   "score_b" => score_b,
      # }
    end

    # debug
    # pp user_tweets

    [ votes_a, votes_b ]
  end
end
