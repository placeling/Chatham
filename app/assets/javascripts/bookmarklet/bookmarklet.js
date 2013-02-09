function getSelText() {
    var SelText = '';
    if (window.getSelection) {
        SelText = window.getSelection();
    } else if (document.getSelection) {
        SelText = document.getSelection();
    } else if (document.selection) {
        SelText = document.selection.createRange().text;
    }
    return SelText;
}


(function () {

    // the minimum version of jQuery we want
    var v = "1.9.1";

    // check prior inclusion and version
    if (window.jQuery === undefined || window.jQuery.fn.jquery < v) {
        var done = false;
        var script = document.createElement("script");
        script.src = "http://ajax.googleapis.com/ajax/libs/jquery/" + v + "/jquery.min.js";
        script.onload = script.onreadystatechange = function () {
            if (!done && (!this.readyState || this.readyState == "loaded" || this.readyState == "complete")) {
                done = true;
                initMyBookmarklet();
            }
        };
        document.getElementsByTagName("head")[0].appendChild(script);
    } else {
        initMyBookmarklet();
    }

    function initMyBookmarklet() {
        (window.myBookmarklet = function () {
            // your JavaScript code goes here!
            alert("bookmarklet");
            //var yourname = prompt("What's your name?","my name...");
        })();
    }

})();