require 'uri'
require 'nokogiri'

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
