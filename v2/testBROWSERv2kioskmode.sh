#!/bin/sh
# Name: Test Browser v2 (kiosk)
# Author: onepointfive-REAL (github)
TITLE='Kiosk Mode'
URL='https://example.com'
## put %s in place of title in config
CONFIG='{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"%s","buttons":[{"id":"KPP_BACK","state":"enabled","handling":"system"}]}}'

FINALCONFIG=${CONFIG//%s/$TITLE}

lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=$URL"

(
    sleep 2
	while true 
	do
		FOREGROUND=$(lipc-get-prop com.lab126.appmgrd activeApp)
		if [ "$FOREGROUND" = "com.lab126.browser" ]; then
			lipc-set-prop com.lab126.chromebar configureChrome "$FINALCONFIG"
		else
			lipc-set-prop com.lab126.appmgrd stop "$FOREGROUND"
			lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser"
		fi
		sleep 1
	done
) &

exit 0