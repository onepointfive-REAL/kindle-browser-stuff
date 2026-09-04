#!/bin/sh
# Name: Test Browser v2 (app look)
# Author: onepointfive-REAL (github)
URL='https://example.com'
TITLE='App Look Type'
## put %s in place of title in config
CONFIG='{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"%s","buttons":[{"id":"KPP_CLOSE","state":"enabled","handling":"system"}]}}'


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