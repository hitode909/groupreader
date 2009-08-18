$(document).ready(
    function(){
        var itemElement = function(feed, item) {
            var element = $("<div>").addClass("item");
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
            if (feed.uri)     footerMenu.append($("<li>").append($(['<a href="', feed.uri, '"><img src="', feed.favicon, '">', feed.name, '</a>'].join(''))));
            if (item.pubDate) footerMenu.append($("<li>").text('at ' + new Date(item.pubDate).toLocaleFormat('%Y-%m-%d %H:%M')));
            if (item.creator) footerMenu.append($("<li>").text('by ' + item.creator));
            footer.append(footerMenu);
            
            element.append(header);
            if (body) element.append(body);
            element.append(footer);
            return element;
        }
        
        var box = $("div.items");
        var uri = ["/group", Feeds.group, "feeds.json"].join("/");
        $.getJSON(uri, {}, function(data) {
            $(data).each(function(){
                var feed = this;
                $.getJSON("/feed/get.json", {uri: this.uri}, function(data) {
                    $(data.items).each(function(){
                        box.append(itemElement(feed, this));
                    });
                });
            });
        });
    }
);