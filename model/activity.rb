class Activity < Sequel::Model
  set_schema do
    primary_key :id
    foreign_key :feed_id,  :null => false
    foreign_key :group_id, :null => false
    text :type
    time :created_at
    time :modified_at
  end
  many_to_one :group
  many_to_one :feed
  create_table unless table_exists?

  def before_create
    self.created_at = Time.now
  end

  def before_save
    self.modified_at = Time.now
  end

  def self.subscribe(group, feed)
    Ramaze::Log.debug "subscribed(#{group.name}, #{feed.title})"
    self.create :group => group , :feed => feed, :type => 'subscribe'
  end

  def self.unsubscribe(group, feed)
    Ramaze::Log.debug "unsubscribed(#{group.name}, #{feed.title})"
    self.create :group => group , :feed => feed, :type => 'unsubscribe'
  end
end
