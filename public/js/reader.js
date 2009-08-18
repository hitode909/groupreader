$(document).ready(
    function(){
        var box = $("div.reader");
        var uri = ["/group", Feeds.group, "feeds.json"].join("/");
        $.getJSON(uri, {}, function(data) {
            $(data).each(function(){
                $.getJSON("/feed/get.json", {uri: this.uri}, function(data) {
                    $(data.items).each(function(){
                        var item = $("<div>").addClass("item").append($("<span>").append($("<a>").attr("href", this.link).text(this.title)));
                        item.append($("<div>").addClass("item-body").append($(this.description)));
                        box.append(item);
                    });
                });
            });
        });
    }
);