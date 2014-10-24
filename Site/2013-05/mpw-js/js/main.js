var mpw;

function updateMPW() {
    update('identity', 'identity');
    mpw = new MPW( $('#userName')[0].value, $('#masterPassword')[0].value );
    updateActive();
}
function updateActive() {
    if (!mpw)
        update('identity');

    else
        mpw.key.then(
            function() {
                update('site');
            },
            function(reason) {
                update('identity', null, reason);
            }
        );
}
function update(active, working, error) {
    // Working
    if (working == 'identity') {
        $('#identity').addClass('working').find('input, select').attr('disabled', 'disabled');
    }
    else {
        $('#userName')[0].value = $('#masterPassword')[0].value = '';
        $('#identity').removeClass('working').find('input, select').removeAttr('disabled');
    }
    if (working == 'site')
        $('#site').addClass('working');
    else
        $('#site').removeClass('working');

    // Active
    if (active == 'identity') {
        $('#identity').addClass('active');
        $('#site').removeClass('active');

        if (!working)
            $('#userName').focus();
    }
    else {
        $('#identity').removeClass('active');
        $('#site').addClass('active');
        $('#siteName').focus();

        if (!working)
            $('#siteName').focus();
    }

    // Error
    $('#error').text(error);
}
function updateSite() {
    update('site', 'site');

    if (!mpw)
        updateActive();

    else
        mpw.generatePassword( $('#siteName')[0].value, $('#siteCounter')[0].valueAsNumber, $('#siteType')[0].value )
           .then( function (sitePassword) {
               $('#sitePassword').val(sitePassword);
               update('site');
           }, function (reason) {
               update('site', null, reason);
           });
}
function selectText(element) {
    var doc = document, range, selection;    

    if (doc.body.createTextRange) { //ms
        range = doc.body.createTextRange();
        range.moveToElementText(element);
        range.select();
    } else if (window.getSelection) { //all others
        selection = window.getSelection();        
        range = doc.createRange();
        range.selectNodeContents(element);
        selection.removeAllRanges();
        selection.addRange(range);
    }
}


$(function() {
    $('#identity form').on('submit', function() {
        updateMPW();
        return false;
    });
    $('#site input, #site select').on('change input keyup', function() {
        updateSite();
    });
    $('#logout').on('click', function() {
        mpw = null;
        updateActive();
    });
    $('#sitePassword').on('click', function() {
        selectText(this);
    });

    updateActive();
});
