module Api
  class GroupController < JsonController
    def index
      name = request[:name]
      group = Group.find(:name => name)
      respond('group not found', 404) unless group
      group.to_hash
    end

    def create
      return unless request.post?
      name = request[:name]
      respond('The group already exist.', 409) if Group.find(:name => name)
      group = Group.create(:name => name)
      group.save.to_hash
    end

    def delete
      return unless request.post?
      name = request[:name]
      group = Group.find(:name => name)
      respond('The group not found', 404) unless group
      group.destroy
      'ok'
    end

    def subscribe
      return unless request.post?
      group_name = url_decode request[:name]
      uri = url_decode request[:uri]
      return unless uri.length
      uris = uri.split(',')
      group = Group.find_or_create(:name => group_name).save
      feeds = uris.map{|u| Feed.find_feeds(u.strip)}.flatten.compact
      feeds.each do |feed|
        begin
          group.add_feed(feed)
        rescue
        else
          Activity.subscribe(group, feed)
        end
      end
      feeds.map(&:to_hash)
    end

    def unsubscribe
      return unless request.post?
      group_name = url_decode request[:name]
      feed_uri = url_decode request[:feed_uri]
      feed = Feed.find(:uri => feed_uri)
      group = Group.find(:name => group_name)
      respond('The group not found', 404) unless group
      begin
        group.remove_feed(feed)
      rescue
      else
        Activity.unsubscribe(group, feed)
      end
      group.to_hash
    end
  end

  class FeedController < JsonController
    def index
      Feed.find(:uri => url_decode(url_decode(request[:uri]))).to_hash
    rescue
      respond('not found', 404)
    end

    def get
      Feed.get(url_decode(request[:uri]))
    end
  end
end
