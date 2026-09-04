# Kindle Browser Chrome Customization Discoveries

> Research and experimentation on Kindle Paperwhite 6 (12th generation), firmware 5.19.6.

## Overview

While experimenting with the Kindle's built-in Chromium browser and the `com.lab126.chromebar` and `com.lab126.appmgrd` services, several useful discoveries were made about controlling the browser's top navigation bar and creating a kiosk-style browser.

These findings were tested directly on a jailbroken Kindle Paperwhite 6 running firmware 5.19.6.

---

# 1. Launching the Kindle Browser

The Kindle browser can be launched through `appmgrd` using:

```sh
lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=https://example.com"
```

This launches the built-in Kindle browser and requests that it navigate to the specified URL.

### Example

```sh
lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser#going?url=https://google.com"
```

### Launching Without Specifying a URL

The browser can also be launched simply with:

```sh
lipc-set-prop com.lab126.appmgrd start "app://com.lab126.browser"
```

This works on the tested Kindle and allows the browser to handle its existing/default page state rather than explicitly supplying a URL.

This is useful for the kiosk watchdog when returning to the browser after another application has been stopped.

---

# 2. Hiding the Browser's URL Bar

The most useful discovery was the `configureChrome` LIPC property.

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"blank"}}'
```

On the Kindle Paperwhite 6, this removes the browser's normal top navigation/URL bar while leaving the webpage itself visible.

This effectively makes the browser look much more like a standalone application.

### Important

The Kindle may restore the browser chrome after navigation. Reapplying the configuration can therefore be necessary.

---

# 3. Using a Title Instead of a Blank Bar

The `topNavBar` template can display a title instead of the normal URL bar.

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"My Browser"}}'
```

This replaces the normal browser navigation bar with a title bar.

---

# 4. Custom Title and System Buttons

Buttons can be supplied through the `buttons` array inside `topNavBar`.

## Close Button

A system-handled close button can be added with:

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"blank","buttons":[{"id":"KPP_CLOSE","state":"enabled","handling":"system"}]}}'
```

Result:

* URL bar hidden
* Browser page visible
* Close button visible
* Close button handled by the Kindle system

## Back Button

`KPP_BACK` also works as an invisible `topNavBar` button on the tested Kindle Paperwhite 6 running firmware 5.19.6.

Example:

```json
{
    "id": "KPP_BACK",
    "state": "enabled",
    "handling": "system"
}
```

A complete configuration can therefore be:

```sh
lipc-set-prop com.lab126.chromebar configureChrome '{"appId":"com.lab126.browser","topNavBar":{"template":"title","title":"My Browser","buttons":[{"id":"KPP_BACK","state":"enabled","handling":"system"}]}}'
```

The `KPP_BACK` button is handled by the Kindle system.

### Invalid Button IDs

An interesting behavior was discovered when using an invalid button identifier.

For example, an unknown ID such as:

```json
"id": "invalid_id"
```

caused the Kindle to display a **flashing Close button** on the tested firmware.

The exact reason for this fallback behavior is currently unknown.

It should not be relied upon for normal applications.

---

# 5. Button Testing

The following identifiers were investigated:

```text
KPP_BACK
back
forward
```

Current results on the tested Kindle Paperwhite 6 / firmware 5.19.6:

| Button ID   | Result                                     |
| ----------- | ------------------------------------------ |
| `KPP_CLOSE` | Confirmed working                          |
| `KPP_BACK`  | Confirmed working / as an invisible button |
| `back`      | Not confirmed / does not work              |
| `forward`   | Not confirmed / does not work              |

`KPP_BACK` should therefore be considered a valid working `topNavBar` button on the tested firmware.

The behavior of `back` and `forward` remains unknown.

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

# Kiosk Mode Script (v2 version)

### How It Works

When the browser is active:

```text
activeApp = com.lab126.browser
```

the watchdog reapplies the browser chrome configuration.

When another application becomes active:

```text
activeApp != com.lab126.browser
```

the watchdog:

1. Saves the foreground application's identifier.
2. Stops that application using `appmgrd stop`.
3. Launches the Kindle browser again.
4. Continues monitoring.

This is different from simply launching the browser again.

Previously, launching the browser without stopping the other application could cause the other application's state/window to remain underneath the browser.

Stopping the foreground application first results in behavior more like:

```text
Browser
   ↓
User opens Settings
   ↓
Settings becomes foreground
   ↓
Watchdog detects Settings
   ↓
Settings is stopped
   ↓
Kindle Home appears briefly
   ↓
Browser launches
   ↓
Kiosk continues
```

The brief appearance of the Kindle Home screen is expected during the transition between stopping the foreground application and launching the browser.

The main user-editable settings are:

```sh
TITLE='Kiosk Mode'
URL='https://example.com'
```

The `%s` placeholder inside `CONFIG` is replaced with the value of `TITLE`:

```sh
FINALCONFIG=${CONFIG//%s/$TITLE}
```

This keeps the JSON configuration readable while allowing the title to be changed from one obvious setting.

---

# Kiosk Escape / Recovery

Because the watchdog continuously relaunches the browser, normal Kindle navigation cannot be used to exit kiosk mode while the watchdog is running.

For development and testing, SSH access provides a recovery method.

The watchdog's shell process can be located using the process tree. For example:

```sh
ps -ef
```

A child such as:

```text
root     12784 10239 ... sleep 1
```

indicates that PID `10239` is the parent process of that `sleep` command.

The watchdog can then be stopped with:

```sh
kill 10239
```

A reboot also terminates the background watchdog.

### Important

A production kiosk should have a deliberate exit mechanism rather than depending solely on SSH or rebooting.

---

# Performance Considerations

The watchdog checks the active application once every second:

```sh
sleep 1
```

The `lipc-get-prop` call is used because the kiosk needs to know which application is actually in the foreground.

Using:

```sh
pgrep
```

would only establish that a process exists. It does not necessarily indicate that the browser is the active application.

Therefore:

```sh
lipc-get-prop com.lab126.appmgrd activeApp
```

is the more appropriate check for this browser implementation.

The one-second polling interval also means the watchdog does not continuously hammer `appmgrd` or `chromebar`.

---

# What We Know So Far

| Feature                                         | Result                                          |
| ----------------------------------------------- | ----------------------------------------------- |
| Launch browser with URL                         | Confirmed                                       |
| Launch browser without URL                      | Confirmed                                       |
| Hide URL/navigation bar                         | Confirmed                                       |
| Show custom title                               | Confirmed                                       |
| Add `KPP_CLOSE`                                 | Confirmed                                       |
| Add `KPP_BACK`                                  | Confirmed / as an invisible button              |
| Remove configured buttons                       | Confirmed                                       |
| Unknown button ID behavior                      | Causes close button to appear                   |
| `back` as topNavBar button                      | Not working / not confirmed                     |
| `forward` as topNavBar button                   | Not working / not confirmed                     |
| Detect active application with `activeApp`      | Confirmed                                       |
| Stop foreground application with `appmgrd stop` | Confirmed                                       |
| Relaunch browser after stopping another app     | Confirmed                                       |
| Kiosk watchdog                                  | Confirmed                                       |
| Browser chrome restored after navigation        | Confirmed; watchdog reapplies configuration     |
| Navigation URL callback                         | Documented, not yet integrated                  |
| Decanter Chrome detection                       | Documented                                      |
| Direct `kindle_browser` launch                  | Not recommended; renderer/GPU problems observed |

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

A persistent kiosk watchdog should especially be tested with SSH/root recovery available, since it can intentionally prevent normal access to other Kindle applications while it is running.
