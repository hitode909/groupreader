if (typeof(GroupReader) == "undefined") {
    GroupReader = {};
}
GroupReader.Pager = {
    page: 1,
    perpage: 20
};
GroupReader.Feeds = [];

(function() {
    var feedElement = function(feed) {
        var elem = $("<div>").addClass("feed-item");

        var a = $("<a>").attr("href", feed.link || feed.uri);
        var favicon = $("<span>").addClass("favicon").append($("<img>").attr({src: feed.favicon}));
        var title = $("<span>").addClass("title").text(feed.title);
        a.append(favicon).append(title);

        var removeButton = $("<span>").addClass("delete-button").append($("<img>").attr({src: "/image/delete.png"}));
        removeButton.click(function(){
            elem.append(loadingElement());
            $.post('/api/group/unsubscribe',
                   { feed_uri: feed.uri,
                     name: GroupReader.group
                   },
                   function(group){
                       $.handleGroup(group);
                   },
                   'json'
                  );
        });
        elem.append(a);
        elem.append(removeButton);
        elem.data("items", []);
        elem.data("feed", feed);
        return elem;
    };

    var loadingElement = function() {
        var elem = $("<span>").addClass("loading-icon");
        elem.append("<img src='/image/ajax.gif'");
        return elem;
    };

    var itemElement = function(feed, item) {
        var element = $("<div>").attr("style", "display: none").addClass("item");
        if (item.pubDate) element.data('date', Date.parse(item.pubDate));
        var header = $("<div>").addClass("item-header");
        header.append($("<a>").addClass("title-link").attr("href", item.link).text(item.title));
        var menu = $("<ul>").addClass("header-info");
        if (feed.link || feed.uri)     menu.append($("<li>").append($("<a>").attr({target: "_blank", href: feed.link || feed.uri}).addClass('source').append($("<img>").attr("src", feed.favicon)).append(document.createTextNode(feed.title))));
        if (item.pubDate) menu.append($("<li>").text(ambtime(new Date(item.pubDate))));
        if (item.creator) menu.append($("<li>").text('by ' + item.creator));
        header.append(menu);
        
        if (item.description.length > 0 && item.title != item.description && item.title != $(item.description).text) {
            var body = $("<div>").addClass("item-body");
            body.append($(item.description).length ? $(item.description) : document.createTextNode(item.description));
        } else {
            var body = false;
        }

        element.append(header);
        if (body) element.append(body);
        return element;
    };


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

            var elem = feedElement(feed);
            elem.append(loadingElement());
            feedTarget.append(elem);
            var callback = function(data) {
                $(".loading-icon", elem).remove();
                if (feed.title != data.title) {
                    $("a .title", elem).text(data.title);
                }
                if (feed.link != data.link) {
                    $("a", elem).attr("href", data.link);
                }

                $(data.items).each(function() {
                    var item = this;
                    elem.data("items").push($.newitem(feed, item, itemTarget));
                });
                $.updatePager();
            };
            if (feed.items) {
                callback(feed);
            } else {
                $.getJSON("/api/feed/get", {uri: feed.uri}, callback);
            }

            return elem;
        },

        newitem: function(feed, item, itemTarget) {
            if (!itemTarget) itemTarget = $(".items");

            var itemElem = itemElement(feed, item);
            $.appendItem(itemElem);
            return itemElem;
        },
        appendItem: function(item) {
            var did = false;
            var newDate = item.data('date');
            $("div.item").each(function() {
                if ($(this).data('date') == newDate &&
                    $('a.source', this).attr('href') == $('a.source', item).attr('href')) {
                    did = true;
                    return false;
                }
                if ($(this).data('date') < newDate) {
                    $(this).before(item);
                    did = true;
                    return false;
                }
                return true;
            });
            if (!did) $('div.items').append(item);
        },
        updatePager: function() {
                var length = GroupReader.Pager.page * GroupReader.Pager.perpage;
                $('.item:gt(' + length + ')').hide();
                $('.item:lt(' + length + ')').show();
                if ($('.more-button').length == 0 && $('.item').length > length) {
                    $.appendMoreButton();
                } else if($('.more-button').length > 0 && $('.item').length <= length) {
                    $.removeMoreButton();
                }
        },
        appendMoreButton: function() {
            var btn = $('<div>').text('more').addClass('more-button');
            btn.click(function() {
                GroupReader.Pager.page++;
                $.updatePager();
            });
            $('.navigation-bottom').append(btn);
        },
        removeMoreButton: function() {
            $('.more-button').remove();
        },
        handleGroup: function(group){
            if (group.feeds) $.handleFeeds(group.feeds);
            if (group.activities) $.handleActivities(group.activities);
            $.updatePager();
        },
        handleActivities: function(activities) {
            $(activities).each(function() {
                $.appendItem($.activityElement(this));
            });
        },
        handleFeeds: function(feeds) {
            $.each(feeds, function(index, val) {
                $.newfeed(val);
            });
            var newUris = $.map(feeds,function(v, i){return v.uri; });
            $(".feed-item").each(function() {
                var elem = this;
                if ($(elem).data("feed") &&
                    $.inArray($(elem).data("feed").uri, newUris) < 0) {
                    if ($(elem).data("items")) {
                        $.each($(elem).data("items"), function(){this.remove();});
                    }
                    $(elem).remove();
                }
            });
        },

        activityElement: function(item) {
            var feed = item.feed;
            var element = $("<div>").attr("style", "display: none").addClass("activity item");
            element.data('date', Date.parse(item.date));
            var header = $("<div>").addClass("item-header");
            var status = item.operation == "subscribe" ? "+" : "-";
            header.append($("<a>").addClass("title-link").attr("href", feed.link).text(status + " " + feed.title));
            var menu = $("<ul>").addClass("header-info");
            menu.append($("<li>").append($("<a>").attr({target: "_blank", href: feed.link}).addClass('source').append($("<img>").attr("src", feed.favicon))));
            menu.append($("<li>").text(ambtime(new Date(item.date))));
            header.append(menu);
            element.append(header);
            return element;
        }
    });
})(jQuery);


$(document).ready(function(){
    $('.newfeed .new-button').click(function() {
        $('.newfeed .new-button').hide();
        $('.newfeed .new-input').show();
    });

    $('.newfeed form').submit(function() {
        var uri = $("input[name='feed-uri']").val();
        if (!uri) return false;
        $('.newfeed .loading').show();

        $.post('/api/group/subscribe',
               { uri: uri,
                 name: GroupReader.group
               },
               function(group){
                   $('.newfeed .loading').hide();
                   $.handleGroup(group);
               },
               'json'
              );

        $('.newfeed .new-button').show();
        $('.newfeed .new-input').hide();
        $("input[name='feed-uri']").val("");

        return false;
    });

    $.getJSON('/api/group', {name: GroupReader.group}, function(group) {
        $.handleGroup(group);
    });
});
