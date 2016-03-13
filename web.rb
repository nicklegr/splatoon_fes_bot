# coding: utf-8

require "bundler"
Bundler.require

require_relative "db"
require_relative "stat"

get "/" do
  config = YAML.load_file('config.yaml')

  stat = Stat.new

  @stat = stat.get
  @stat_min = stat.get(config["team_a_words_min"], config["team_b_words_min"])

  @last_update = Tweet.desc(:created_at).first.created_at
  # @tweet_count = Tweet.count()

  slim :index
end

get "/ranking" do
  config = YAML.load_file('config.yaml')

  start_time = Time.parse(config['fes_period']['start'])
  end_time = Time.parse(config['fes_period']['end'])

  tweets = Tweet
    .where(:created_at => { '$gte' => end_time })
    .and({ :text => /パワーを記録したぜ！/ })
    .and({ :text => %r|https://t\.co/| })

  powers = tweets.map do |e|
    e.text =~ /(\d+)(ガンガン|だいじに)パワー/
    power_text = $&
    power = $1.to_i

    e.text =~ %r|https://t\.co/\w+|
    url = $&

    {
      :screen_name => e.screen_name,
      :text => e.text,
      :power => power,
      :power_text => power_text,
      :url => url,
    }
  end

  users = powers.group_by{ |e| e[:screen_name] }

  @ranking = users.map do |k, v|
    v.max_by{ |e| e[:power] }
  end

  @ranking = @ranking.sort_by{ |e| e[:power] }.reverse

  slim :ranking
end
