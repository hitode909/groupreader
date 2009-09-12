module Api
  class GroupController < JsonController
    before_all do
      @name = url_decode request[:name]
      @uri   = url_decode request[:uri]
      @group      = Group.find(:name => @name)
      @feed       = Feed.find(:uri => @uri)
    end

    def index
      respond('group not found', 404) unless @group
      @group.uniq_feeds
    end

    def subscribe
      return unless request.post?
      return unless @uri.length
      uris = @uri.split(',')
      @group ||= Group.create(:name => @name)
      feeds = uris.map{|u| Feed.find_feeds(u.strip)}.flatten.compact
      feeds.each do |feed|
        begin
          @group.add_feed(feed)
        rescue
        else
          Activity.subscribe(@group, feed)
        end
      end
      @group.uniq_feeds
    end

    def unsubscribe
      return unless request.post?
      respond('The group not found', 404) unless @group
      respond('The feed not found', 404) unless @feed
      begin
        @group.remove_feed(@feed)
      rescue
      else
        Activity.unsubscribe(@group, @feed)
      end
      @group.uniq_feeds
    end
  end

  class FeedController < JsonController
    def index
      Feed.find(:uri => url_decode(url_decode(request[:uri])))
    rescue
      respond('not found', 404)
    end

    def get
      Feed.get(url_decode(request[:uri]))
    end
  end
end
