require 'rss'
require 'time'
require 'nokogiri'
require 'sanitize'

class Entry < Sequel::Model
  set_schema do
    primary_key :id
    String :uri, :unique => true, :null => false
    String :title
    String :description, :text => true
    String :creator
    Boolean :valid, :default => true
    foreign_key :feed_id
    time :pub_date
    time :created_at
    time :modified_at
  end
  many_to_one :feed
  create_table unless table_exists?

  def before_create
    self.created_at = Time.now
  end

  def before_save
    self.modified_at = Time.now
  end

  def as_hash
    {
      'title' => self.title,
      'pubDate' => self.pub_date.rfc822,
      'creator' => self.creator,
      'description' => self.description,
      'uri' => self.uri,
    }

  end

end
