$(document).ready(function(){
    $('.newfeed .new-button').click(function() {
        $('.newfeed .new-button').hide();
        $('.newfeed .new-input').show();
    });

    $('.newfeed form').submit(function() {
        var feed_uri = $("input[name='feed-uri']").val();
        if (!feed_uri) return false;
        $.post('/api/group/subscribe',
               { feed_uri: feed_uri,
                 name: GroupReader.group
               },
               function(data){
                   console.log(data);
               },
               'json'
              );

        $('.newfeed .new-button').show();
        $('.newfeed .new-input').hide();
        $("input[name='feed-uri']").val("");

        return false;
    });
});
