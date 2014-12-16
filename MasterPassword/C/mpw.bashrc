## Added by Master Password
source bashlib
mpw() {
    _copy() {
        if hash pbcopy 2>/dev/null; then
            pbcopy
        elif hash xclip 2>/dev/null; then
            xclip
        else
            cat; echo 2>/dev/null
            return
        fi
        echo >&2 "Copied!"
    }

    # Empty the clipboard
    :| _copy 2>/dev/null

    # Ask for the user's name and password if not yet known.
    MP_FULLNAME=${MP_FULLNAME:-$(ask 'Your Full Name:')}

    # Start Master Password and copy the output.
    printf %s "$(MP_FULLNAME=$MP_FULLNAME command mpw "$@")" | _copy
}
