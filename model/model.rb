# -*- coding: utf-8 -*-
class Feed < Sequel::Model
  set_schema do
    primary_key :id
    String :uri, :unique => true, :null => false
    Boolean :valid, :default => true
    time :created_at
    time :modified_at
  end

  def before_create
    self.created_at = Time.now
  end

  def before_save
    self.modified_at = Time.now
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

  create_table unless table_exists?
end

unless DB.table_exists?(:feeds_groups)
  DB.create_table :feeds_groups do
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
