# Kindle Browser Chrome Customization Discoveries

> Research and experimentation on Kindle Paperwhite 6 (12th generation), firmware 5.19.6.

## Overview

While experimenting with the Kindle's built-in Chromium browser and the `com.lab126.chromebar` service, several useful discoveries were made about controlling the browser's top navigation bar.

These findings were tested directly on a jailbroken Kindle Paperwhite 6 running firmware 5.19.6.

---

## 1. Launching the Kindle Browser

The Kindle browser can be launched through `appmgrd` using:

```sh
lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=https://example.com"
```

This launches the built-in Kindle browser and requests that it navigate to the specified URL.

### Example

```sh
lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=https://google.com"
```

---

## 2. Hiding the Browser's URL Bar

The most useful discovery was the `configureChrome` LIPC property.

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"blank"}}'
```

On the Kindle Paperwhite 6, this removes the browser's normal top navigation/URL bar while leaving the webpage itself visible.

This effectively makes the browser look much more like a standalone application.

### Important

The Kindle may restore the browser chrome after navigation. Reapplying the configuration can therefore be necessary.

---

## 3. Using a Title Instead of a Blank Bar

The `topNavBar` template can display a title instead of the normal URL bar.

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"My Browser"}}'
```

This replaces the normal browser navigation bar with a title bar.

---

## 4. Using a Title and Close Button

A system-handled close button can be added to the top navigation bar.

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"blank","buttons":[{"id":"KPP_CLOSE","state":"enabled","handling":"system"}]}}'
```

### Result

* URL bar: hidden
* Browser page: visible
* Close button: visible
* Close button is handled by the Kindle system

This makes the browser behave visually more like a standalone Kindle application.

---

## 5. Back and Forward Buttons

Several possible button identifiers were investigated.

`KPP_BACK` exists as a Kindle/Decanter Chrome enum, but testing it inside:

```json
"topNavBar": {
    "buttons": [...]
}
```

did **not** produce a visible Back button on the tested firmware.

Likewise, using:

```json
"id": "back"
```

and:

```json
"id": "forward"
```

did not produce visible navigation buttons.

Therefore, these should **not** currently be considered confirmed `topNavBar` button IDs for the Kindle Paperwhite 6.

### Confirmed

```text
KPP_CLOSE
```

works as a `topNavBar` button.

### Not confirmed for topNavBar

```text
KPP_BACK
back
forward
```

Further research is required to determine how the modern Kindle browser's Back/Forward controls are implemented.

---

# Kindle Browser Launcher

The Kindle's `/usr/bin/browser` script was also inspected.

The browser is not normally launched directly as root. When called as root, it switches to the `framework` user:

```sh
if [[ "$(whoami)" = "root" ]]; then
    exec su - framework /usr/bin/browser
fi
```

The normal launcher eventually starts:

```text
/usr/bin/chromium/kindle_browser
```

with a large collection of Amazon-specific Chromium arguments.

Among them are:

```text
--content-shell-hide-toolbar
--content-shell-host-window-cord=0,215
--disable-gpu
--disable-gpu-sandbox
--disable-seccomp-filter-sandbox
```

and several Kindle-specific low-end-device and rendering options.

## Important

Launching `kindle_browser` directly without the normal Amazon environment is not equivalent to launching it through `/usr/bin/browser`.

A direct test using:

```sh
/usr/bin/chromium/kindle_browser --no-sandbox --content-shell-hide-toolbar "https://google.com"
```

resulted in GPU/renderer problems.

Therefore, the normal Kindle browser launcher should be preferred.

---

# What We Know So Far

| Feature                        | Result                         |
| ------------------------------ | ------------------------------ |
| Launch browser with URL        | Confirmed                      |
| Hide URL/navigation bar        | Confirmed                      |
| Show custom title              | Confirmed                      |
| Add `KPP_CLOSE`                | Confirmed                      |
| Remove all configured buttons  | Confirmed                      |
| `KPP_BACK` as topNavBar button | Not working                    |
| `back` as topNavBar button     | Not working                    |
| `forward` as topNavBar button  | Not working                    |
| Navigation URL callback        | Documented, not yet integrated |
| Decanter Chrome detection      | Documented                     |

---

# Simple App-Like Browser with Custom Title and Close Button

The following launcher opens the Kindle browser with a custom title and a Close button in the top navigation bar:

```
#!/bin/sh
# Name: Test Browser

URL='https://example.com'

lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=$URL"

(
    sleep 1

    while pgrep -f '/usr/bin/chromium/kindle_browser' >/dev/null 2>&1
    do
        lipc-set-prop com.lab126.chromebar configureChrome \
            '{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"My Browser","buttons":[{"id":"KPP_CLOSE","state":"enabled","handling":"system"}]}}'

        sleep 1
    done
) &

exit 0
```

The `title` field controls the text displayed in the top navigation bar. The `KPP_BACK` button is configured as a system-handled Back button.

The loop is used because navigation can cause the browser to restore its chrome.

> `sleep 0.5` should not be used here. The Kindle's `sleep` command on the tested system requires a whole-number interval.

---

# Firmware / Device

These discoveries were made on:

```text
Device: Kindle Paperwhite 6 (12th generation)
Firmware: 5.19.6
Browser: Amazon Kindle built-in Chromium browser
Access: Jailbroken / root SSH
```

Results may differ on other Kindle models or firmware versions.

---

# Disclaimer

These are experimental findings from direct testing. Kindle internal APIs are undocumented or incompletely documented in many cases and may change between firmware versions.

Commands involving LIPC, `chromebar`, `appmgrd`, or the browser should be tested carefully on a device where recovery access is available.

