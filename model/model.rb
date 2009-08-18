# -*- coding: utf-8 -*-
require 'uri'
require 'kconv'
require 'open-uri'
require 'rss'


class Feed < Sequel::Model
  set_schema do
    primary_key :id
    String :uri, :unique => true, :null => false
    String :title
    Boolean :valid, :default => true
    time :created_at
    time :modified_at
  end

  def name
    self.title or self.uri
  end

  def favicon_uri
    "http://favicon.hatena.ne.jp/?url=" + URI.encode(self.uri)
  end

  def self.json(feed_uri)
    feed = Feed.find(:uri => feed_uri)
    result = { };
    source = open(feed_uri).read.toutf8
    rss = begin RSS::Parser.parse(source) rescue RSS::Parser.parse(source, false) end
    result['title'] = rss.channel.title
    result['link'] = rss.channel.link
    result['creator'] = rss.channel.dc_creator
    result['description'] = rss.channel.description
    result['items'] = rss.items.map do |item|
      {
        'title' => item.title,
        'pubDate' => (item.dc_date or item.pubDate),
        'creator' => item.dc_creator,
        'description' => (item.content_encoded or item.description),
        'link' => item.link,
      }
    end

    if feed and rss.channel.title
      feed.title = rss.channel.title
      feed.save
    end

    if feed and not feed.valid
      feed.valid = true
      feed.save
    end

    result
  rescue => e
    if feed
      feed.valid = false
      feed.save
    end
    e
  end

  def before_create
    self.created_at = Time.now
  end

  def after_create
    # get title and set to title
    Thread.new do
      source = open(self.uri).read.toutf8
      rss = begin RSS::Parser.parse(source) rescue RSS::Parser.parse(source, false) end
      self.title = rss.channel.title
      self.save
    end
  end

  def before_save
    self.modified_at = Time.now
  end

  def before_destroy
    self.remove_all_groups
  end

  many_to_many :groups
  create_table unless table_exists?
end

class Group < Sequel::Model
  set_schema do
    primary_key :id
    String :name, :unique => true, :null => false
    String :description
    time :created_at
    time :modified_at
  end
  many_to_many :feeds

  def before_create
    self.created_at = Time.now
  end

  def before_save
    self.modified_at = Time.now
  end

  def before_destroy
    self.remove_all_feeds
  end

  create_table unless table_exists?
end

unless DB.table_exists?(:feeds_groups)
  DB.create_table :feeds_groups do
    primary_key :id
    foreign_key :feed_id, :table => :feeds
    foreign_key :group_id, :table => :groups
  end
end

# あとでEntry作る
# class Entry < Sequel::Model
#   set_schema do
#     primary_key :id
#     String :uri, :unique => true, :null => false
#     String :title
#     String :body
#     time :posted_at
#   end
#   many_to_many :feeds
# end
