#!/bin/sh
# Name: Test Browser v2 (title, no url bar)
# Author: onepointfive-REAL (github)
TITLE='No URL Bar'
URL='https://example.com'
## put %s in place of title in config
CONFIG='{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"%s"}}'

FINALCONFIG=${CONFIG//%s/$TITLE}
lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=$URL"

(
    sleep 2

    while [ "$(lipc-get-prop com.lab126.appmgrd activeApp)" = "com.lab126.browser" ]
    do
        lipc-set-prop com.lab126.chromebar configureChrome "$FINALCONFIG"
        sleep 1
    done
) &

exit 0
