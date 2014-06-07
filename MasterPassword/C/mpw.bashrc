## Added by Master Password
source bashlib
mpw() {
    _copy() {
        if hash pbcopy 2>/dev/null; then
            pbcopy
        elif hash xclip 2>/dev/null; then
            xclip
        else
            cat
            return
        fi
        echo >&2 "Copied!"
    }

    # Empty the clipboard
    :| _copy 2>/dev/null

    # Ask for the user's name and password if not yet known.
    MP_USERNAME=${MP_USERNAME:-$(ask -s 'Your Full Name:')}

    # Start Master Password and copy the output.
    printf %s "$(MP_USERNAME=$MP_USERNAME command mpw "$@")" | _copy
}
