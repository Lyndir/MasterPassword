$(function() {
    $("*[data-hero]").hover(function() {
        let active = this;
        $(this).parents("header").addClass( "hero_" + $(this).attr("data-hero") );
        $("*[data-hero]").each(function() {
            if (this != active)
                $(this).parents("header").removeClass( "hero_" + $(this).attr("data-hero") );
        });
    });

    $.each($(".widget_calculator"), function(i, calculator) {
        calculator = $(calculator);
        var display = calculator.find("input[type=text]");
        var lhs = null, operator = null;

        function calculator_apply() {
            if (lhs && operator == '-')
                display.val(parseInt(lhs) - parseInt(display.val()));
            else if (lhs && operator == '+')
                display.val(parseInt(lhs) + parseInt(display.val()));
        }

        calculator.find("input[type=button]").click(function() {
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

            calculator.find("input").removeClass('selected');
            if (operator)
                calculator.find("input[value='" + operator + "']").addClass('selected');
        });
    });
});

