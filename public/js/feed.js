(function() {
    jQuery.extend({
        newfeed: function(feed, feedTarget, itemTarget){
            if (!feed.uri) return false;
            if (!feedTarget) feedTarget = $(".feed-list");

            feed = jQuery.extend({
                name: feed.uri,
                favicon: "http://favicon.hatena.ne.jp/?uri=" + encodeURIComponent(feed.uri)
            }, feed);

            var feedElement = function(feed) {
                console.log(feed);
                var elem = $("<div>").addClass("feed-item");
                var a = $("<a>").attr("href", feed.link || feed.uri);
                a.append($(["<img src='", feed.favicon, "' title='", feed.name, "' alt='", feed.name, "'>"].join("")));
                a.append(document.createTextNode(feed.name));
                elem.append(a);
                return elem;
            };
            
            var loadingElement = function() {
                var elem = $("<span>").addClass("loading-icon");
                elem.append("<img src='/image/ajax.gif'");
                return elem;
            };
            
            var elem = feedElement(feed);
            elem.append(loadingElement());
            feedTarget.append(elem);
            $.getJSON("/api/feed/get", {uri: feed.uri}, function(data) {
                $(".loading-icon", elem).remove();
                // TODO: ’¤³’¤³’¤Î’¥í’¥¸’¥Ã’¥¯’¤Þ’¤È’¤â’¤Ë’¤¹’¤ë
                if (feed.name != data.title || feed.link != data.link) {
                    feed.name = data.title;
                    feed.link = data.link;
                    elem.html(feedElement(feed).html());
                }
                $(data.items).each(function() {
                    //$.newitem(this);
                });
            });
            
            return this;
        },

        newitem: function(item, itemTarget) {
            if (!itemTarget) itemTarget = $(".items");
        }
    });
})(jQuery);


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

    $.getJSON('/api/group', {name: GroupReader.group}, function(data) {
        $(data.feeds).each(function() {
            $.newfeed(this);
        });
    });
});
