# Albarran Road Assistant

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Agent location tracking

The app publishes `users/{firebaseUid}.currentLocation` and
`users/{firebaseUid}.presence` while the Firebase session remains active.
Available agents send a heartbeat every 45 seconds; the active-order screen
uses a higher update frequency. Signing out stops tracking and immediately
writes `presence.isOnline: false`.

Android runs tracking as a foreground location service and shows a persistent
notification. Android 11 and newer may require the agent to select "Allow all
the time" manually in the app location settings. iOS uses the `location`
background mode and displays the system background-location indicator.

Neither operating system guarantees execution after the user force-quits the
app, revokes location access, disables device location, or applies aggressive
battery restrictions. The API therefore also marks a location stale when its
timestamp exceeds `ADMIN_AGENT_LOCATION_STALE_SECONDS` (120 seconds by
default).
