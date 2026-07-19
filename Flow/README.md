# Flow

Flow is an offline, native Cocoa Flow Library. This implementation provides:

- a SQLite-backed Flow data model;
- a Flow Library startup view;
- a Flow Detail view;
- a New Flow view with structural Flow and subcategory choices;
- title, kind, production stage, completion, next action and notes;
- a programmatic Cocoa interface, requiring no modern nib or storyboard support.

## Compatibility rules

The source uses manual memory management, classic Objective-C syntax and the SQLite C API. It deliberately avoids ARC, blocks, Grand Central Dispatch, Objective-C literals and newer Cocoa APIs so the project can be moved to an Xcode 2.5 Tiger build later.

## Build on a current Mac

```sh
make
open build/Flow.app
```

The initial database is created in the user's Application Support directory under `Flow/Flow.sqlite`.

## Source layout

- `Sources/FLProject.*` — portable project record.
- `Sources/FLProjectStore.*` — SQLite schema and project persistence.
- `Sources/FLApplicationController.*` — Cocoa single-window, three-view interface.
- `Sources/main.m` — application entry point.

## Data model

The library has seven flows: Musical Pieces, Instruments, Thoughts, Promotion, Apps, Purchases, and Health. Only Musical Pieces (Songs and Instrumentals) and Instruments (Synthesizers, Guitars, and Drum Modules) have structural subcategories. Other distinctions are stored as classification, tags, or metadata.

Collections are separate from flows. Albums, EPs, Playlists, and Live Sets reference ordered Song or Instrumental IDs through `collection_items`, without copying their data. The `relationships` table connects any two flow items as `source → relationship → target`.

## Import and export

Use the Import and Export buttons to exchange a proprietary `.flowlib` archive. It is a versioned Flow Library XML property-list archive containing Flow items, Collections and their ordered musical-piece references, and relationships. Import validates the archive signature and preserves IDs so references remain intact.
