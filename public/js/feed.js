(function() {
    jQuery.extend({
        newfeed: function(feed, feedTarget, itemTarget){
            if (!feed.uri) return false;
            if (!feedTarget) feedTarget = $(".feed-list");

            var feedUris = $(".feed-item", feedTarget).map(function(){ return $(this).data("feed").uri; });
            if ($.inArray(feed.uri, feedUris) != -1) return false;

            feed = jQuery.extend({
                name: feed.uri,
                favicon: "http://favicon.hatena.ne.jp/?uri=" + encodeURIComponent(feed.uri)
            }, feed);

            // TODO ’¤´’¤Á’¤ã’¤Ã’¤È’¤·’¤Æ’¤ë
            var feedElement = function(feed) {
                var elem = $("<div>").addClass("feed-item");
                var a = $("<a>").attr("href", feed.link || feed.uri);
                a.append($("<span>").addClass("favicon").append($(["<img src='", feed.favicon, "' title='", feed.name, "' alt='", feed.name, "'>"].join(""))));
                a.append($("<span>").addClass("title").text(feed.name));
                elem.append(a);
                elem.data("items", []);
                elem.data("feed", feed);
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
                // TODO: ’¤³’¤³’¤Î’¥í’¥¸’¥Ã’¥¯’¤¬’¤è’¤¯’¤Ê’¤µ’¤½’¤¦’¤Ê’¤Î’¤Ç’¤¢’¤È’¤Ç’¸«’¤ë
                if (feed.name != data.title) {
                    $("a .title", elem).text(data.title);
                }
                if (feed.link != data.link) {
                    $("a", elem).attr("href", data.link);
                }

                $(data.items).each(function() {
                    elem.data("items").push($.newitem(feed, this));
                });
            });
            
            return this;
        },

        // TODO: ’¤³’¤Î’°ú’¿ô’¤Ï’¤É’¤¦’¤Ê’¤Î’¤«
        newitem: function(feed, item, itemTarget) {
            if (!itemTarget) itemTarget = $(".items");

            var itemElement = function(feed, item) {
                var element = $("<div>").addClass("item");
                if (item.pubDate) element.data('date', Date.parse(item.pubDate));
                var header = $("<div>").addClass("item-header");
                header.append($(['<a href="', item.link, '">', item.title, '</a>'].join('')));

                if (item.title != item.description && item.title != $(item.description).text) {
                    var body = $("<div>").addClass("item-body");
                    body.append($(item.description).length ? $(item.description) : document.createTextNode(item.description));
                } else {
                    var body = false;
                }

                var footer = $("<div>").addClass("item-footer");
                var footerMenu = $("<ul>");
                if (feed.uri)     footerMenu.append($("<li>").append($(['<a target="_blank" href="', feed.uri, '"><img src="', feed.favicon, '">', feed.name, '</a>'].join(''))));
                if (item.pubDate) footerMenu.append($("<li>").text('at ' + new Date(item.pubDate).toLocaleFormat('%Y-%m-%d %H:%M')));
                if (item.creator) footerMenu.append($("<li>").text('by ' + item.creator));
                footer.append(footerMenu);
                
                element.append(header);
                element.append(footer);
                if (body) element.append(body);
                return element;
            };

            var appendItem = function(item) {
                var did = false;
                var newId = item.data('date');
                $("div.item").each(function() {
                    if ($(this).data('date') < newId) {
                        $(this).before(item);
                        did = true;
                        return false;
                    }
                    return true;
                });
                if (!did) $('div.items').append(item);
            };

            var itemElem = itemElement(feed, item);
            appendItem(itemElem);
            return itemElem;
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
                   $.newfeed(data);
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
