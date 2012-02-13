// jQuery plugin: PutCursorAtEnd 1.0
// http://plugins.jquery.com/project/PutCursorAtEnd
// by teedyay
//
// Puts the cursor at the end of a textbox/ textarea

// codesnippet: 691e18b1-f4f9-41b4-8fe8-bc8ee51b48d4
(function($)
{
    jQuery.fn.putCursorAtEnd = function()
    {
    return this.each(function()
    {
        $(this).focus()

        // If this function exists...
        if (this.setSelectionRange)
        {
        // ... then use it
        // (Doesn't work in IE)

        // Double the length because Opera is inconsistent about whether a carriage return is one character or two. Sigh.
        var len = $(this).val().length * 2;
        this.setSelectionRange(len, len);
        }
        else
        {
        // ... otherwise replace the contents with itself
        // (Doesn't work in Google Chrome)
        $(this).val($(this).val());
        }

        // Scroll to the bottom, in case we're in a tall textarea
        // (Necessary for Firefox and Google Chrome)
        this.scrollTop = 999999;
    });
    };
})(jQuery);


// Show the content element referenced by the document's hash
function updateHash() {
    var hashContent = document.location.hash.split('/', 1)[0];
    var foundCurrent = false;
    var contentElement = $(hashContent + "-content");
    if (contentElement.size() != 1)
        contentElement = $("#about-content");

    $("#content section").each(function (i) {
        if (foundCurrent)
            this.className = "future";
        else {
            if (this.id == contentElement.attr("id")) {
                foundCurrent = true;
                this.className = "current";
            } else
                this.className = "past";
        }
    });
}

