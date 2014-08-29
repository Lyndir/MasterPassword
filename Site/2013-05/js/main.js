$(function(){
    $.stellar();

    window.onscroll = function() {
        document.getElementById("scrollDown").style.opacity = Math.max(0, 200 - window.scrollY) / 200;
    };
});

