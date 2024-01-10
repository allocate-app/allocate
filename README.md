# allocate

An offline-first To-Do application for avoiding burnout.

## Who is this for?

This application is primarily intended for neurodivergent folk who struggle with burnout. I wanted
to make
something which better suited my own needs and thought others may find it useful.

I hope that, one day, this app will be fully accessible, at the moment, it is not.

## Installation:

This is not yet ready for release, but if you would like to play with the project,
feel free to clone the project and build using Flutter. You will require a supabase api key
(and a full online implementation).

Main has not been fully implemented, but the application can be run using
the NavigationTester class, used for Integration testing. The database will delete on a graceful
application close - remove the default flag when Initializing IsarService to persist the data.

## What has been implemented so far:

Basic offline functionality CRUD:
-Creating tasks, routines, deadlines, reminders, task grouping
-Repeating tasks, reminders, deadlines (partially)
-Theme modifications
-Accessibility modifications (partially)

## What still requires implementation:

-Main Application and routing
-User accounts
-Online data synchronization
-Usage documentation

## Roadmap and future plans:

-see [ROADMAP.md]{ROADMAP.md}

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
