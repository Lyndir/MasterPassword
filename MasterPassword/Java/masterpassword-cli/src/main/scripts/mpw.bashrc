source bashlib
mpw() {
    _nocopy() { echo >&2 "$(cat)"; }
    _copy() { "$(type -P pbcopy || type -P xclip || echo _nocopy)"; }

    # Empty the clipboard
    :| _copy 2>/dev/null

    # Ask for the user's name and password if not yet known.
    MP_USERNAME=${MP_USERNAME:-$(ask -s 'Your Full Name:')}
    MP_PASSWORD=${MP_PASSWORD:-$(ask -s 'Master Password:')}

    # Start Master Password and copy the output.
    printf %s "$(MP_USERNAME=$MP_USERNAME MP_PASSWORD=$MP_PASSWORD command mpw "$@")" | _copy
}
