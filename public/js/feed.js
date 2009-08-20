$(document).ready(function(){
    $('.newfeed').click(function() {
        $(this).unbind('click');
        this.innerHTML = '<form method="POST" action="/group/' + GroupReader.group + '/subscribe"><input name="feed_uri" type="text" size="50"></input></form>';
    });
});