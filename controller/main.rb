class MainController < Controller
  # the index action is called automatically when no other action is specified
  def index
    @title = "Group Reader"
    @groups = Group.all
  end
end

class GroupController < Controller
  def index(group_name)
    respond('group not found', 404) unless group_name
    @group = Group.find(:name => group_name)
    @group_name = group_name
    @title = 'group/' + @group_name
  end
end
