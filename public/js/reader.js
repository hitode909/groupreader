$(document).ready(
    function(){
        var itemElement = function(feed, item) {
            var element = $("<div>").addClass("item");
            if (item.pubDate) element.attr('id', Date.parse(item.pubDate));
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
            var newId = item.attr('id');
            $("div.item").each(function() {
                if (this.id < newId) {
                    $(this).before(item);
                    did = true;
                    return false;
                }
                return true;
            });
            if (!did) $('div.items').append(item);
        };

        feedIcon = function(feed) {
            var parent = $('.feed-list');
            var element = $(
                ['<span class="feed"><img src="', feed.favicon, '"><span class="feed-name">',feed.name,'</span></span>'].join('')
            );
            parent.append(element);
        };
        
        var uri = ["/group", GroupReader.group, "feeds.json"].join("/");
        $.getJSON(uri, {}, function(data) {
            $(data).each(function(){
                var feed = this;
                feedIcon(this);
                $.getJSON("/feed/get.json", {uri: this.uri}, function(data) {
                    $(data.items).each(function(){
                        appendItem(itemElement(feed, this));
                    });
                });
            });
        });
    }
);