$(function() {
    $("*[data-hero]").hover(function() {
        let active = this;
        $(this).parents("header").addClass( "hero_" + $(this).attr("data-hero") );
        $("*[data-hero]").each(function() {
            if (this != active)
                $(this).parents("header").removeClass( "hero_" + $(this).attr("data-hero") );
        });
    });

    var lhs = null;
    var operator = null;
    function calculator_apply() {
        var display = $("#calculator input[type=text]");
        if (lhs && operator == '-')
            display.val(parseInt(lhs) - parseInt(display.val()));
        else if (lhs && operator == '+')
            display.val(parseInt(lhs) + parseInt(display.val()));
    }
    $("#calculator input[type=button]").click(function() {
        var display = $("#calculator input[type=text]");
        var value = $(this).val();

        if (value == '-' || value == '+') {
            if (operator == value && !display.val())
                operator = null;

            else {
                calculator_apply();
                operator = value;
                lhs = display.val();
                display.val('');
            }
        } else if (value == 'C') {
            operator = null;
            lhs = null;
            display.val('');
        } else if (value == '=')
            calculator_apply();
        else
            display.val(display.val() + '' + value);

        $("#calculator input").removeClass('selected');
        if (operator)
            $("#calculator input[value='" + operator + "']").addClass('selected');
    });
});

