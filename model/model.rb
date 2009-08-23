require 'uri'
require 'kconv'
require 'open-uri'
require 'memcache'

module ExternalResource
  @cache = MemCache.new('localhost:11211', {:namespace, 'groupreader',})
  def self.get(uri)
    old = @cache[uri]
    return old if old
    source = open(uri).read
    @cache.set(uri, source, 10 * 60)
    source
  end
end

unless DB.table_exists?(:feeds_groups)
  DB.create_table :feeds_groups do
    primary_key :id
    foreign_key :feed_id, :table => :feeds
    foreign_key :group_id, :table => :groups
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
