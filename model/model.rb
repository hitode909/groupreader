# -*- coding: utf-8 -*-
require 'uri'
require 'kconv'
require 'open-uri'
require 'rss'
require 'time'
require 'nokogiri'
require 'memcache'
require 'Logger'

module ExternalResource
  @cache = MemCache.new('localhost:11211', {:namespace, 'groupreader', :logger, Logger.new(STDOUT)})
  def self.get(uri)
    old = @cache[uri]
    return old if old
    source = open(uri).read.toutf8
    @cache.set(uri, source, 10 * 60)
    source
  end
end

class Feed < Sequel::Model
  set_schema do
    primary_key :id
    String :uri, :unique => true, :null => false
    String :title
    Boolean :valid, :default => true
    foreign_key :blog_id
    time :created_at
    time :modified_at
  end
  many_to_one :blog

  def self.find_feeds(uri)
    if Feed.find(:uri => uri)
      return [Feed.find(:uri => uri)]
    elsif Blog.find(:uri => uri)
      return Blog.find(:uri => uri).feeds
    end

    # return new feeds
    source = ExternalResource.get(uri)
    input = Nokogiri(source)
    if input.html?
      Blog.create(:uri => uri).feeds
    else
      [Feed.create(:uri => uri)]
    end
  end

  def self.get(feed_uri)
    feed = Feed.find(:uri => feed_uri)
    result = { };
    source = ExternalResource.get(feed_uri)
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

    result
  rescue => e
    if feed
      feed.valid = false
      feed.save
    end
    e
  end

  def to_hash
    { :name    => self.title,
      :uri     => self.uri,
      :favicon => self.blog.favicon,
      :link    => self.blog.uri,
    }
  end

  def before_create
    self.created_at = Time.now
  end

  def after_create
    self.fetch_meta_data
  end

  def fetch_meta_data
    return if self.blog and self.title
    p "fetch feed(#{self.uri})"

    source = ExternalResource.get(self.uri)
    rss = begin RSS::Parser.parse(source) rescue RSS::Parser.parse(source, false) end
    self.title = rss.channel.title
    unless self.blog_id
      blog_uri = rss.channel.link
      if blog_uri
        self.blog = Blog.find_or_create(:uri => blog_uri)
      end
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
    p "fetch blog(#{self.uri})"
    uriobj = URI.parse(self.uri)
    xml = Nokogiri(ExternalResource.get(uri))
    feed_uris = xml.xpath('//link[@rel="alternate"][@type="application/rss+xml"]').each do |link|
      uri = (uriobj + link['href']).to_s
      feed = Feed.find(:uri => uri)
      feed = Feed.create(:uri => uri, :blog_id => self.id) unless feed
      self.add_feed feed
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
