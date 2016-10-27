var mpw, error;

function updateMPW() {
    mpw = null;
    startWork();
    mpw = new MPW( $('#userName')[0].value, $('#masterPassword')[0].value, $('#version')[0].value );
    mpw.key.then(
        function() {
            doneWork();
        },
        function(reason) {
            error = reason;
            mpw = null;
            doneWork();
        }
    );
}
function startWork() {
    update(true);
}
function doneWork() {
    update(false);
}
function update(working) {
    var screen = mpw? 'site': 'identity';

    // Screen Name
    if (screen == 'identity') {
        $('#identity').addClass('active');

        if (!working)
            $('#userName').focus();
    }
    else {
        $('#identity').removeClass('active');
        $('#userName')[0].value = $('#masterPassword')[0].value = '';
    }

    if (screen == 'site') {
        $('#site').addClass('active');

        if (!working)
            $('#siteName').focus();
    }
    else {
        $('#site').removeClass('active');
        $('#siteName')[0].value = $('#sitePassword')[0].value = '';
    }

    // Working
    if (working && screen == 'identity')
        $('#identity').addClass('working').find('input, select').attr('disabled', 'disabled');
    else
        $('#identity').removeClass('working').find('input, select').removeAttr('disabled');

    if (working && screen == 'site')
        $('#site').addClass('working');
    else
        $('#site').removeClass('working');

    // Error
    $('#error').text(error);
}
function updateSite() {
    if (!mpw) {
        doneWork();
        return
    }

    startWork();
    mpw.generatePassword( $('#siteName')[0].value, $('#siteCounter')[0].valueAsNumber, $('#siteType')[0].value )
       .then( function (sitePassword) {
           $('#sitePassword').text(sitePassword);
           doneWork();
       }, function (reason) {
           error = reason;
           doneWork();
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
        doneWork();
    });
    $('#sitePassword').on('click', function() {
        selectText(this);
    });

    doneWork();
});
