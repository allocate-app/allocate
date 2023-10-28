# allocate

An offline-first To-Do application for avoiding burnout.

## Who is this for?

This application is primarily intended for neurodivergent folk who struggle with burnout. I wanted
to make
something which better suited my own needs and thought others may find it useful.

I hope that, one day, this app will be fully accessible, at the moment, it is not.

## Installation:

This is not yet ready for release, but if you would like to play with the project,
feel free to clone the project and build using Flutter. You will be required to implement the
Constants class before this will run.

Main has not been fully implemented, but the application can be run using
the NavigationTester class, used for Integration testing. The database will delete on a graceful
application close - modify the testing environment in IsarService.dart to persist the data.

## What has been implemented so far:

Basic offline functionality CRUD:
-Tasks and To-dos
-Routines
-Reminders
-Deadlines
-Task Groups

## What still requires implementation:

-Main application setup and loop
-GUI refactor to accommodate mobile-views
-User accounts
-Online data synchronization
-Theming & customization
-Use documentation

## Roadmap and future plans:

-Properly accommodate screen readers
-Fully accessible design

## How to use:

- TBD

[//]: # (## Getting Started)

[//]: # ()

[//]: # (This project is a starting point for a Flutter application.)

[//]: # ()

[//]: # (A few resources to get you started if this is your first Flutter project:)

[//]: # ()

[//]: # (- [Lab: Write your first Flutter app]&#40;https://docs.flutter.dev/get-started/codelab&#41;)

[//]: # (- [Cookbook: Useful Flutter samples]&#40;https://docs.flutter.dev/cookbook&#41;)

[//]: # ()

[//]: # (For help getting started with Flutter development, view the)

[//]: # ([online documentation]&#40;https://docs.flutter.dev/&#41;, which offers tutorials,)

[//]: # (samples, guidance on mobile development, and a full API reference.)
