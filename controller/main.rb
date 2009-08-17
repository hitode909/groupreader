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
  # the index action is called automatically when no other action is specified
  def index(group_name)
    g = Group.find([:name => group_name])
    @title = "Welcome to "
  end
end

class FeedController < Controller
  def index
  end
end
