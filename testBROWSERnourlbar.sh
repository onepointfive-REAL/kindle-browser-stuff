#!/bin/sh
# Name: Test Browser (no url bar)
# Author: onepointfive-REAL (github)

URL='https://example.com'

lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=$URL"

(
    sleep 1

    while pgrep -f '/usr/bin/chromium/kindle_browser' >/dev/null 2>&1
    do
        lipc-set-prop com.lab126.chromebar configureChrome \
            '{"appId":"com.lab126.browser","topNavBar":{"template":"blank"}}'


        sleep 1
    done
) &

exit 0