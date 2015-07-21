# coding: utf-8

require "bundler"
Bundler.require

require_relative "db"
require_relative "stat"

get "/" do
  @stat = Stat.get
  @stat_team_name_only = Stat.get(["レモン"], ["ミルク"])

  @last_update = Tweet.desc(:created_at).first.created_at
  @tweet_count = Tweet.count()

  slim :index
end
