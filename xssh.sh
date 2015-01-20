# Extended ssh

declare -f _xssh_timestamp >/dev/null || {
    # Turn case-insensitive matching temporarily on, if necessary.
    nocasematchWasOff=0
    shopt nocasematch >/dev/null || nocasematchWasOff=1
    (( nocasematchWasOff )) && shopt -s nocasematch

    target=$(readlink -e "$1")
    case "${OSTYPE}" in
        darwin*) _xssh_timestamp() { stat -f %m "$target" 2>/dev/null || echo 0; } ;;
              *) _xssh_timestamp() { stat --printf='%Y' "$target" 2>/dev/null || echo 0; } ;;
    esac

    # Restore state of 'nocasematch' option, if necessary.
    (( nocasematchWasOff )) && shopt -u nocasematch
    unset nocasematchWasOff
}

xssh() {

    ssh_bin=$(type -P ssh)

    _xssh() {
        local files=".xssh_rc"
        [[ -d "$HOME/.xssh_rc.d" ]] && files="$files .xssh_rc.d"
        if [[ -z "$xssh_encrypt_script"    || \
              -z "$xssh_encrypt_timestamp" || \
              $( _xssh_timestamp "$HOME/.xssh_rc") -gt "$xssh_encrypt_timestamp" || \
              $( _xssh_timestamp "$HOME/.xssh_rc.d") -gt "$xssh_encrypt_timestamp"  \
           ]]; then
            echo "Using new .xssh_rc and .xssh_rc.d files..."
            xssh_encrypt_script=$( tar cj -h -C "$HOME" $files | openssl enc -a -A )
            xssh_encrypt_script_size=$( echo "$xssh_encrypt_script" | wc -c)
            if [[ "$xssh_encrypt_script_size" -gt 128000 ]]; then
                echo -e ".xssh_rc and .xssh_rc.d files must be less than 128kb\ncurrent size: $xssh_encrypt_script_size bytes" >&2
                return 1
            fi
            # echo "$xssh_encrypt_script_size"
            xssh_encrypt_timestamp=$(date '+%s')
        fi
        #set -xv
         $ssh_bin -t "$@" \
"export XSSH_HOME=\$(mktemp -d -t .xssh_$USER.XXXX)
echo '$xssh_encrypt_script' | openssl enc -a -A -d | tar xj -C \$XSSH_HOME
trap \"rm -rf \$XSSH_HOME\" 0
bash --rcfile \$XSSH_HOME/.xssh_rc";
        #set +xv
    }

    local nbargs word script_name oldExpandAliases
    nbargs=0
    for word in "$@"; do
        case "$word" in
            -*)  : option ;;
            *=*) : setting env ;;
            *) nbargs=$((++nbargs)) ;;
        esac
    done

    case "$nbargs" in
        0) echo "Vous devez spécifier un host" ;;
        1) _xssh "$@" ;;
        *) $ssh_bin "$@" ;;
    esac
}
typeset -f _ssh >/dev/null && shopt -u hostcomplete && complete -F _ssh xssh

# Local Variables:      #
# mode: ksh             #
# tab-width: 4          #
# indent-tabs-mode: nil #
# End:                  #
#
# vi: set expandtab ts=4 sw=4 sts=4: #
