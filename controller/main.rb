# -*- coding: utf-8 -*-
# Default url mappings are:
#  a controller called Main is mapped on the root of the site: /
#  a controller called Something is mapped on: /something
# If you want to override this, add a line like this inside the class
#  map '/otherurl'
# this will force the controller to be mounted on: /otherurl

class MainController < Controller
  # the index action is called automatically when no other action is specified
  def index
    @title = "Welcome!!"
  end

end

class GroupController < Controller
  map '/group'

  def index(group_name)
    redirect MainController.r(:index) unless group_name

    if request.post?
      group = Group.find_or_create(:name => group_name)
      redirect GroupController.r(:index, group_name)
    elsif request.get?
      @group = Group.find([:name => group_name])
      @group_name = group_name
      if @group
        @title = "グループ - " + @group.name
        render_view(:index_hasgroup)
      else
        render_view(:index_nogroup)
      end
    end
  end
end

class FeedController < Controller
  def index
  end
end
