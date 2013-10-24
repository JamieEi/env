#!/bin/sh
# See:
#   http://git-annex.branchable.com/special_remotes/hook/
#   https://github.com/basak/glacier-cli#setup
echo hello
set -e
case "$ANNEX_ACTION" in
    glacier-store-hook)
        glacier archive upload --name=\"$ANNEX_KEY\" vault-name \"$ANNEX_FILE\"
    ;;
    glacier-retrieve-hook)
        glacier archive retrieve -o \"$ANNEX_FILE\" vault-name \"$ANNEX_KEY\"
    ;;
    glacier-remove-hook)
        glacier archive delete vault-name \"$ANNEX_KEY\"
    ;;
    glacier-checkpresent-hook)
        glacier archive checkpresent vault-name --quiet \"$ANNEX_KEY\"
    ;;
esac
