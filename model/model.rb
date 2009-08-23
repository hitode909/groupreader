require 'uri'
require 'kconv'
require 'open-uri'
require 'memcache'

module ExternalResource
  @cache = MemCache.new('localhost:11211', {:namespace, 'groupreader',})
  def self.get(uri)
    old = @cache[uri]
    return old if old
    begin
      source = open(uri).read
    rescue                      # ToDo better way
      return ''
    end
    @cache.set(uri, source, 10 * 60)
    source
  end
end

unless DB.table_exists?(:feeds_groups)
  DB.create_table :feeds_groups do
    foreign_key :feed_id, :table => :feeds
    foreign_key :group_id, :table => :groups
    unique [:feed_id, :group_id]
  end
end

unless DB.table_exists?(:blogs_feeds)
  DB.create_table :blogs_feeds do
    foreign_key :blog_id, :table => :blogs
    foreign_key :feed_id, :table => :feeds
    unique [:blog_id, :feed_id]
  end
end

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
