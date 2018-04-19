$(function() {
    /* Hero */
    $("header nav *[data-hero]").hover(function() {
        $(this).parents("header").attr( "data-hero", $(this).attr("data-hero") );
    });

    /* Paroller */
    $("*[data-paroller-factor]").paroller();

    /* Widget: Calculator */
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

