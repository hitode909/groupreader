class MainController < Controller
  def index
    @title = "Group Reader"
    @groups = Group.all
  end
end

class GroupController < Controller
  def index(group_name = nil)
    redirect(MainController.r) unless group_name
    @group = Group.find(:name => group_name)
    @group_name = group_name
    @title = 'group/' + @group_name
  end
end
