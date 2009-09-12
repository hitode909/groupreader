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

  def uniq_feeds
    test_block = lambda{ |hash|
      hash['items'].map{|item| item['link']}
    }
    self.feeds.combination(2).each do |a, b|
      next unless a and b
      ah = a.cached_hash
      bh = b.cached_hash
      if ah and bh and
          test_block.call(ah) == test_block.call(bh)
        Ramaze::Log.debug "auto delete"
        Ramaze::Log.debug [ah['uri'], bh['uri']]
        Ramaze::Log.debug [test_block.call(ah), test_block.call(bh)]
        Ramaze::Log.debug ah['uri'].length < bh['uri'].length ? a.uri : b.uri
        self.remove_feed(ah['uri'].length < bh['uri'].length ? a : b)
        self.save
      end
    end
  end

  create_table unless table_exists?
end
