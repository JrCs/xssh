# Extended ssh
xssh() {

    ssh_bin=$(type -P ssh)

    _timestamp() {
        # Turn case-insensitive matching temporarily on, if necessary.
        local nocasematchWasOff=0
        shopt nocasematch >/dev/null || nocasematchWasOff=1
        (( nocasematchWasOff )) && shopt -s nocasematch

        case "${OSTYPE}" in
            darwin*) stat -f %m "$1";;
                  *) stat --printf='%Y' "$1";;
        esac
        # Restore state of 'nocasematch' option, if necessary.
        (( nocasematchWasOff )) && shopt -u nocasematch
    }
    _xssh() {
        local source_script=$(readlink -e "$HOME/.xssh_rc")
        if [[ -z "$xssh_encrypt_script"    || \
              -z "$xssh_encrypt_timestamp" || \
              $( _timestamp $source_script ) -gt "$xssh_encrypt_timestamp" \
           ]]; then
            echo "Using new \`$source_script' file as remote bash script..."
            xssh_encrypt_script=$( gzip --stdout $source_script | openssl enc -a -A )
            xssh_encrypt_timestamp=$(date '+%s')
        fi
        script_name=$(mktemp -u "/tmp/.xssh_${USER}_XXXXXXXXXXXXX")
        $ssh_bin -t "$@" \
         "export xssh_script=$script_name; echo '$xssh_encrypt_script' | \
         openssl enc -a -A -d | zcat >\$xssh_script; \
         exec bash --rcfile \$xssh_script";
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
