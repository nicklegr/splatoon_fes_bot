# coding: utf-8

require "bundler"
Bundler.require

require_relative "db"
require_relative "stat"

get "/" do
  config = YAML.load_file('config.yaml')

  stat = Stat.new

  @stat = stat.get
  @stat_team_name_only = stat.get(config["team_a_words_min"], config["team_b_words_min"])

  @last_update = Tweet.desc(:created_at).first.created_at
  @tweet_count = Tweet.count()

  slim :index
end
