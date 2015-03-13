#!/usr/bin/env bash
source bashcomplib

# completing the 'mpw' command.
_comp_mpw() {
    local optarg= cword=${COMP_WORDS[COMP_CWORD]} pcword=
    (( COMP_CWORD )) && pcword=${COMP_WORDS[COMP_CWORD - 1]} 

    case $pcword in
        -u) # complete full names.
            COMPREPLY=( ~/.mpw.d/*.mpsites )
            [[ -e $COMPREPLY ]] || COMPREPLY=()
            COMPREPLY=( "${COMPREPLY[@]##*/}" ) COMPREPLY=( "${COMPREPLY[@]%.mpsites}" )
            ;;
        -t) # complete types.
            COMPREPLY=( maximum long medium basic short pin name phrase )
            ;;
        -c) # complete counter.
            COMPREPLY=( 1 )
            ;;
        -V) # complete versions.
            COMPREPLY=( 0 1 2 3 )
            ;;
        -v) # complete variants.
            COMPREPLY=( password login answer )
            ;;
        -C) # complete context.
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
                if [[ -e ~/.mpw.d/"$fullName.mpsites" ]]; then
                    IFS=$'\n' read -d '' -ra COMPREPLY < <(awk -F$'\t' '!/^ *#/{sub(/^ */, "", $2); print $2}' ~/.mpw.d/"$fullName.mpsites")
                    printf -v _comp_title 'Sites for %s' "$fullName"
                else
                    # Default list from the Alexa Top 500
                    COMPREPLY=(
                        163.com 360.cn 9gag.com adobe.com alibaba.com aliexpress.com amazon.com
                        apple.com archive.org ask.com baidu.com battle.net booking.com buzzfeed.com
                        chase.com cnn.com comcast.net craigslist.org dailymotion.com dell.com
                        deviantart.com diply.com disqus.com dropbox.com ebay.com engadget.com
                        espn.go.com evernote.com facebook.com fedex.com feedly.com flickr.com
                        flipkart.com github.com gizmodo.com go.com goodreads.com google.com
                        huffingtonpost.com hulu.com ign.com ikea.com imdb.com imgur.com
                        indiatimes.com instagram.com jd.com kickass.to kickstarter.com linkedin.com
                        live.com livedoor.com mail.ru mozilla.org naver.com netflix.com newegg.com
                        nicovideo.jp nytimes.com pandora.com paypal.com pinterest.com pornhub.com
                        qq.com rakuten.co.jp reddit.com redtube.com shutterstock.com skype.com
                        soso.com spiegel.de spotify.com stackexchange.com steampowered.com
                        stumbleupon.com taobao.com target.com thepiratebay.se tmall.com
                        torrentz.eu tripadvisor.com tube8.com tubecup.com tudou.com tumblr.com
                        twitter.com uol.com.br vimeo.com vk.com walmart.com weibo.com whatsapp.com
                        wikia.com wikipedia.org wired.com wordpress.com xhamster.com xinhuanet.com
                        xvideos.com yahoo.com yandex.ru yelp.com youku.com youporn.com ziddu.com
                    )
                fi
            fi ;;
    esac
    _comp_finish_completions
}

#complete -F _show_args mpw
complete -o nospace -F _comp_mpw mpw
