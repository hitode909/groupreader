# -*- coding: utf-8 -*-

require 'json'

class MainController < Controller
  # the index action is called automatically when no other action is specified
  def index
    @title = "Welcome!!"
    @groups = Group.all
  end
end

class GroupController < Controller
  def index(group_name)
    @group = Group.find(:name => group_name)
    if group_name
      @group_name = group_name
      @title = 'group/' + @group_name
      if @group
        render_view(:index_hasgroup)
      else
        render_view(:index_nogroup)
      end
    end
  end

  def create(group_name)
    # raise unless request.post?
    group = Group.create(:name => group_name)
    group.description = request[:description] if request[:description]
    group.save
  ensure
    redirect GroupController.r(group_name)
  end

  def delete(group_name)
    # raise unless request.post?
    group = Group.find(:name => group_name)
    raise unless group
    group.destroy
  ensure
    redirect MainController.r
  end

  def feeds(group_name)
    group = Group.find(:name => group_name)
    group.feeds.map{|f| f.to_hash}
  end

  def subscribe(group_name)
#     return unless group_name
#     return unless request.post?
    feed_uri = url_decode request[:feed_uri]
    feed = Feed.find_or_create(:uri => feed_uri)
    feed.save
    group = Group.find(:name => group_name)
    if feed and group.feeds_dataset.filter(:uri => feed_uri).count == 0
      group.add_feed(feed) if feed
    end
  ensure
    redirect GroupController.r(group_name)
  end

  def unsubscribe(group_name)
    feed_uri = url_decode request[:feed_uri]
    feed = Feed.find(:uri => feed_uri)
    group = Group.find(:name => group_name)
    if feed and group.feeds_dataset.filter(:uri => feed_uri).count == 1
      group.remove_feed(feed)
    end
  ensure
    redirect GroupController.r(group_name)
  end

  def error(group_name)
    respond('', 403)
  end
end

class FeedController < Controller
  def index(feed_uri)
    @feed = Feed.find(:uri => url_decode(feed_uri))
    if @feed
      @title = @feed.name
      render_view(:index_has_feed)
    else
      respond('', 404)
    end
  end

  def get
    feed_uri = request[:uri]
    json = Feed.json(url_decode(feed_uri))
  rescue e
    respond(e.to_s, 403)
  end
end

class ApiController < JsonController
end
