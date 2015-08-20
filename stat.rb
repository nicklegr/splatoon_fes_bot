# coding: utf-8

require_relative "db"

class Stat
  def initialize
    @config = YAML.load_file('config.yaml')
    @start_time = Time.parse(@config['announced_at'])
    @end_time = Time.parse(@config['fes_period']['end'])
  end

  def get(team_a_words=@config["team_a_words"], team_b_words=@config["team_b_words"])
    votes_a, votes_b, votes_undecided = count_vote(team_a_words, team_b_words)

    total_vote = votes_a + votes_b + votes_undecided

    rate_a_in_ab = 100.0 * votes_a / (votes_a + votes_b) # 中立を含めないAチームの割合
    rate_b_in_ab = 100.0 * votes_b / (votes_a + votes_b) # 中立を含めないBチームの割合

    # 得票率をひっくり返すのに必要な勝率
    # 例:
    # Aチーム: 40 + 52.5*4 = 280
    # Bチーム: 60 + 47.5*4 = 280
    diff = (rate_a_in_ab - rate_b_in_ab).abs
    defeat_win_rate = 50.0 + (diff / 4 / 2)

    {
      :team_a_name => @config["team_a_name"],
      :team_b_name => @config["team_b_name"],
      :votes_a => votes_a,
      :votes_b => votes_b,
      :votes_undecided => votes_undecided,
      :total_vote => total_vote,
      :rate_a => 100.0 * votes_a / total_vote,
      :rate_b => 100.0 * votes_b / total_vote,
      :rate_undecided => 100.0 * votes_undecided / total_vote,
      :rate_a_in_ab => rate_a_in_ab,
      :rate_b_in_ab => rate_b_in_ab,
      :winner => votes_a > votes_b ? @config["team_a_name"] : @config["team_b_name"],
      :loser => votes_a > votes_b ? @config["team_b_name"] : @config["team_a_name"],
      :defeat_win_rate => defeat_win_rate,
    }
  end

  def count_vote(team_a_words, team_b_words)
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

    votes_a = votes_b = votes_undecided = 0

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
      else
        votes_undecided += 1
      end

      # debug
      # tweets << {
      #   "score_a" => score_a,
      #   "score_b" => score_b,
      # }
    end

    # debug
    # pp user_tweets

    [ votes_a, votes_b, votes_undecided ]
  end
end
