#!/bin/sh
# Name: Test Browser v2 (no url bar)
# Author: onepointfive-REAL (github)
URL='https://example.com'
CONFIG='{"appId":"com.lab126.browser","topNavBar":{"template":"blank"}}'

lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=$URL"

(
    sleep 2

    while [ "$(lipc-get-prop com.lab126.appmgrd activeApp)" = "com.lab126.browser" ]
    do
        lipc-set-prop com.lab126.chromebar configureChrome "$CONFIG"
        sleep 1
    done
) &

exit 0