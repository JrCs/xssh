# Extended ssh
xssh() {
    _timestamp() {
	case "$OSTYPE" in
	    Darwin*) stat -f %m "$1";;
                  *) stat --printf='%Y' "$1";;
	esac
    }
    _xssh() {
        local source_script=$HOME/.xssh_rc 
        if [[ -z "$xssh_encrypt_script"    || \
              -z "$xssh_encrypt_timestamp" || \
              $( _timestamp $source_script ) -gt "$xssh_encrypt_timestamp" \
           ]]; then
            echo "Using new \`$source_script' file as remote bash script..."
            xssh_encrypt_script=$( gzip --stdout $source_script | openssl enc -a -A )
            xssh_encrypt_timestamp=$(date '+%s')
        fi
        script_name=$(mktemp -u "/tmp/.xssh_${USER}_XXXXXXXXXXXXX")
        ssh -t "$@" \
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

    # Disable aliases temporary
    oldExpandAliases=$(shopt -p expand_aliases)
    shopt -u expand_aliases

    case "$nbargs" in
        0) echo "Vous devez spécifier un host" ;;
        1) _xssh "$@" ;;
        *) ssh   "$@" ;;
    esac

    # Restore expand_aliases mode
    eval "$oldExpandAliases"

}
typeset -f _ssh >/dev/null && shopt -u hostcomplete && complete -F _ssh xssh

# Local Variables:      #
# mode: ksh             #
# tab-width: 4          #
# indent-tabs-mode: nil #
# End:                  #
#
# vi: set expandtab ts=4 sw=4 sts=4: #