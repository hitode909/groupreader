$(document).ready(
    function(){
        var box = $("div.items");
        var uri = ["/group", Feeds.group, "feeds.json"].join("/");
        $.getJSON(uri, {}, function(data) {
            $(data).each(function(){
                $.getJSON("/feed/get.json", {uri: this.uri}, function(data) {
                    $(data.items).each(function(){
                        var item = $("<div>").addClass("item").append($("<span>").append($("<a>").attr("href", this.link).text(this.title)));
                        var body = $(this.description).length ? $(this.description) : document.createTextNode(this.description);
                        item.append($("<div>").addClass("item-body").append(body));
                        box.append(item);
                    });
                });
            });
        });
    }
);