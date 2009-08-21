# -*- coding: utf-8 -*-
require 'uri'
require 'kconv'
require 'open-uri'
require 'rss'
require 'time'
require 'nokogiri'

class Feed < Sequel::Model
  set_schema do
    primary_key :id
    String :uri, :unique => true, :null => false
    String :title
    String :link
    String :favicon
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

  def self.find_feeds(uri)
    if Feed.find(:uri => uri)
      return [Feed.find(:uri => uri)]
    end

    source = open(uri).read
    input = Nokogiri(source)
    feeds = []
    if input.html?
      blog = Blog.get(uri, source)
      blog.feed_uris.each { |feed_uri|
        feed = Feed.find_or_create(:uri => feed_uri)
        feed.favicon = blog.favicon
        feed.link = uri
        feed.title = blog.title
        feed.save
        feeds << feed
      }
    else
      feeds << Feed.find_or_create(:uri => uri)
    end
    feeds
  end

  def self.get(feed_uri)
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
        'pubDate' => (item.dc_date || item.pubDate).rfc822,
        'creator' => item.dc_creator,
        'description' => (item.content_encoded || item.description),
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

  def to_hash
    { :name    => self.name,
      :uri     => self.uri,
      :favicon => self.favicon_uri,
      :link    => self.link,
    }
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

  def to_hash
    { :name => self.name,
      :description => self.description,
      :feeds => self.feeds.map(&:to_hash),
    }
  end

  create_table unless table_exists?
end

# ToDo: Sequelのモデルにする？
class Blog
  attr_accessor :feed_uris, :favicon, :title
  def self.get(uri, source = nil)
    uriobj = URI.parse(uri)
    xml = Nokogiri(source || open(uri).read)
    blog = self.new
    blog.feed_uris = begin xml.xpath('//link[@rel="alternate"][@type="application/rss+xml"]').map{|link|
        (uriobj + link['href']).to_s
      } rescue [] end
    blog.favicon = xml.xpath('//link[@rel="shortcut icon"]').first['href'] rescue nil
    blog.title = xml.xpath('//title').first.content rescue nil
    blog
  end
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
