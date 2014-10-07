$(function(){
    $.stellar();

    window.onscroll = function() {
        document.getElementById("scrollDown").style.opacity = Math.max(0, 200 - window.scrollY) / 200;
    };

    if (document.location.hash == "#video")
        toggleMovie();

    $("video")[0].addEventListener("playing", function() {
        $(this).parents().find(".fallback").hide();
    }, true);
});

function toggleMovie() {
    if ($("header").hasClass("play")) {
        $("header").removeClass("play");
        $("header video")[0].pause();
    } else {
        $("header").addClass("play");
        $("header video")[0].play();
    }
}

