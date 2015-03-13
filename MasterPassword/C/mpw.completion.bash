#!/usr/bin/env bash
source bashcomplib

# completing the 'mpw' command.
_comp_mpw() {
    local optarg= cword=${COMP_WORDS[COMP_CWORD]} pcword

    if (( COMP_CWORD > 0 )); then
        pcword=${COMP_WORDS[COMP_CWORD - 1]} 

        case $pcword in
            -u) optarg=user ;;
            -t) optarg=type ;;
            -c) optarg=counter ;;
            -V) optarg=version ;;
            -v) optarg=variant ;;
            -C) optarg=context ;;
        esac
    fi

    case $optarg in
        user) # complete full names.
            COMPREPLY=( ~/.mpw.d/*.mpsites ) COMPREPLY=( "${COMPREPLY[@]##*/}" ) COMPREPLY=( "${COMPREPLY[@]%.mpsites}" )
            ;;
        type) # complete types.
            COMPREPLY=( maximum long medium basic short pin name phrase )
            ;;
        counter) # complete counter.
            COMPREPLY=( 1 )
            ;;
        version) # complete versions.
            COMPREPLY=( 0 1 2 3 )
            ;;
        variant) # complete variants.
            COMPREPLY=( password login answer )
            ;;
        context) # complete context.
            ;;
        *)
            # previous word is not an option we can complete, complete site name (or option if leading -)
            if [[ $cword = -* ]]; then
                COMPREPLY=( -u -t -c -V -v -C )
            else
                local w fullName=$MP_FULLNAME
                for (( w = 0; w < ${#COMP_WORDS[@]}; ++w )); do
                    [[ ${COMP_WORDS[w]} = -u ]] && fullName=$(xargs <<< "${COMP_WORDS[w + 1]}") && break
                done
                IFS=$'\n' read -d '' -ra COMPREPLY < <(awk -F$'\t' '!/^ *#/{sub(/^ */, "", $2); print $2}' ~/.mpw.d/"$fullName.mpsites")
                printf -v _comp_title 'Sites for %s' "$fullName"
            fi ;;
    esac
    _comp_finish_completions
}

#complete -F _show_args mpw
complete -o nospace -F _comp_mpw mpw
