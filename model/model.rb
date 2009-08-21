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
    foreign_key :blog_id
    time :created_at
    time :modified_at
  end
  many_to_one :blog


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
      :favicon => self.favicon,
      :link    => self.link,
    }
  end

  def before_create
    self.created_at = Time.now
  end

  def after_create
    # get title and set to title
    self.fetch_meta_data
  end

  def fetch_meta_data
    return if self.blog

    source = open(self.uri).read.toutf8
    rss = begin RSS::Parser.parse(source) rescue RSS::Parser.parse(source, false) end
    blog_uri = rss.channel.link
    if blog_uri
      self.blog = Blog.find_or_create(:uri => blog_uri)
    else
      p 'no link'
    end
    self.save
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
      :feeds => self.feeds.map(&:to_hash),
    }
  end

  create_table unless table_exists?
end

class Blog < Sequel::Model
  set_schema do
    primary_key :id
    String :uri, :unique => true, :null => false
    String :title
    String :favicon
    Boolean :valid, :default => true
    time :created_at
    time :modified_at
  end
  one_to_many :feeds
  create_table unless table_exists?

  def before_create
    self.created_at = Time.now
  end

  def after_create
    self.fetch_meta_data
  end

  def before_save
    self.modified_at = Time.now
  end

  def before_destroy
    self.feeds.each {|feed| feed.destroy}
  end

  def fetch_meta_data
    p 'fetch blog'
    uriobj = URI.parse(self.uri)
    xml = Nokogiri(open(uri).read)
    feed_uris = xml.xpath('//link[@rel="alternate"][@type="application/rss+xml"]').each do |link|
      uri = (uriobj + link['href']).to_s
      self.add_feed Feed.find_or_create(:uri => uri)
    end

    self.favicon = xml.xpath('//link[@rel="shortcut icon"]').first['href'] rescue (uriobj + '/favicon.ico').to_s
    begin self.title = xml.xpath('//title').first.content rescue nil end
    self.save
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
