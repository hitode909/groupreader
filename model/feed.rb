require 'rss'
require 'time'
require 'nokogiri'
require 'sanitize'

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
    source = ExternalResource.get(feed_uri)
    parse_feed(feed, source)
  rescue => e
    if feed
      feed.valid = false
      feed.save
    end
    e
  end

  def self.parse_feed(feed, source)
    result = { };
    rss = begin RSS::Parser.parse(source) rescue RSS::Parser.parse(source, false) end
    result['title'] = rss.channel.title
    result['link'] = rss.channel.link
    result['uri'] = feed.uri
    result['favicon'] = feed.blog.favicon
    result['creator'] = rss.channel.dc_creator
    result['description'] = rss.channel.description
    result['items'] = rss.items.map do |item|
      {
        'title' => item.title,
        'pubDate' => (item.dc_date || item.pubDate).rfc822,
        'creator' => item.dc_creator,
        'description' => Sanitize.clean((item.content_encoded || item.description),
          Sanitize::Config::RELAXED),
        'link' => item.link,
      }
    end

    result
  end

  def cached_hash
    source = self.cached_source
    return unless source
    self.class.parse_feed(self, source)
  end

  def cached_source
    ExternalResource.try_get(self.uri)
  end

  def to_hash
#     source = ExternalResource.try_get(self.uri)
#     source ? self.class.parse_feed(self, source) :
    { :title    => self.title,
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
    Ramaze::Log.debug "fetch feed(#{self.uri})"

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
