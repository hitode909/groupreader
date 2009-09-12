class Group < Sequel::Model
  set_schema do
    primary_key :id
    String :name, :unique => true, :null => false
    time :created_at
    time :modified_at
  end
  many_to_many :feeds
  one_to_many  :activities

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
      :activities => self.activities.map(&:to_hash)
    }
  end

  def to_simple_hash
    { :name => self.name
    }
  end

  create_table unless table_exists?
end
