# FastReport — File & Directory Map

> Reference for AI agents. Every file and directory in this project with its exact purpose, contents, and relationships.

## Project Overview

- **What**: Native macOS app base — classic window with sidebar navigation (Home + Settings)
- **Stack**: Swift 6.4, SwiftUI + AppKit hybrid, Swift Package Manager (no Xcode project)
- **Target**: macOS 26+
- **Language mode**: Swift 5 (SwiftUIMacros plugin is NOT available — `@State`, `@Binding`, `@Environment` cannot be used)
- **Observation**: Uses `@Observable` (ObservationMacros IS available). Bindings are created manually via `Binding(get:set:)`.
- **Dock icon**: `.regular` activation policy. Closing the window quits the app (`applicationShouldTerminateAfterLastWindowClosed`).

---

## Root Files

```
FastReport/
├── Package.swift              SPM manifest. swift-tools-version:6.2, target macOS .v26, language mode .v5. Single executable target "FastReport" with path "Sources". Depends on sparkle-project/Sparkle (from 2.6.4). linkerSettings add -rpath @executable_path and @executable_path/../Frameworks so the Sparkle.framework resolves both from .build/debug (local dev) and from Contents/Frameworks (packaged .app).
├── Package.resolved           Pins the resolved Sparkle version. Scripts/build_appcast.sh and Scripts/generate_sparkle_keys.sh read this to download matching Sparkle CLI tools.
├── dev.sh                     Hot reload script. On start, kills any already-running FastReport instance (even from a previous/untracked session) before the first build. Uses fswatch to watch Sources/ recursively. On file change: kills running app → swift build → relaunch. Run with: bash dev.sh
├── .gitignore                 Ignores .build/, .swiftpm/, xcodeproj, DerivedData, .DS_Store, build/, dist/, .sparkle-tools/
└── AI_PROJECT_MAP.md          THIS FILE. Project map for AI agents.
```

## Releases & Auto-Update

```
.github/workflows/
└── release.yml                Triggers on push of tags matching v*.*.*. Builds release binary, packages FastReport.app
                                (via Scripts/package_app.sh), signs it for Sparkle and generates the appcast
                                (via Scripts/build_appcast.sh), creates a GitHub Release with the .zip + appcast.xml,
                                then deletes every other release so only the latest stays published.
                                Needs repo secrets: SPARKLE_PRIVATE_KEY, SPARKLE_PUBLIC_KEY (see Scripts/generate_sparkle_keys.sh).

Packaging/
└── Info.plist                 Template Info.plist for the packaged app. Placeholders __VERSION__, __OWNER__, __REPO__,
                                __SPARKLE_PUBLIC_KEY__ are substituted by Scripts/package_app.sh.
                                SUFeedURL points to https://github.com/<owner>/<repo>/releases/latest/download/appcast.xml
                                (GitHub's stable "latest" redirect — always resolves to the one release kept published).
                                SUEnableAutomaticChecks + SUAutomaticallyUpdate are both true: updates download and
                                install automatically without prompting.

Scripts/
├── package_app.sh              Builds build/FastReport.app from .build/release, embeds Sparkle.framework into
│                                Contents/Frameworks, fills in Packaging/Info.plist, ad-hoc codesigns (deep, including
│                                Sparkle's nested XPC services/Autoupdate/Updater.app), zips to dist/FastReport-<version>.zip.
├── build_appcast.sh             Downloads the Sparkle CLI tools matching Package.resolved's pinned version, runs
│                                generate_appcast against dist/ to sign the zip (EdDSA) and emit dist/appcast.xml.
│                                Reads the private key from SPARKLE_PRIVATE_KEY (never written to disk outside a temp file).
└── generate_sparkle_keys.sh     Run locally (not in CI) once to generate the Sparkle EdDSA key pair via the official
                                 generate_keys tool. Private key goes to the login Keychain / GitHub secret
                                 SPARKLE_PRIVATE_KEY; public key goes into Packaging/Info.plist and GitHub secret
                                 SPARKLE_PUBLIC_KEY.
```

No code signing certificate / Apple Developer ID is configured yet — builds are ad-hoc signed only, so
first launch after download/update will show a Gatekeeper warning until a Developer ID is added later.

## Config

```
.vscode/
└── launch.json                VS Code Swift debugger configs (Debug + Release). Uses swift-extension launch type.
```

---

## Sources — Application Code

All Swift source files live under `Sources/`. SPM compiles every `.swift` file as a single target.

```
Sources/
├── App/
│   ├── FastReportApp.swift        ENTRY POINT. @main enum FastReportApp; AppDelegate creates MainWindowController
│   │                               and quits when the last window closes.
│   ├── MainWindowController.swift Creates the classic NSWindow (titled, closable, miniaturizable, resizable,
│   │                               750x510, min 750x510, centered, zoom/maximize disabled) hosting MainWindowView. Owns AppState.
│   └── UpdaterController.swift    SPARKLE WRAPPER. @Observable class around SPUStandardUpdaterController; starts on init.
│                                   Behavior comes from Contents/Info.plist (see Packaging/Info.plist). No-op outside a packaged .app.
├── Models/
│   ├── AppSection.swift            Sidebar entries (enum: home, settings — id, title, icon). Add a case to add a sidebar row.
│   ├── AppState.swift              @Observable: selectedSection, openProject, isReportMode, isAutomationMode, automationIndex,
│   │                               updater, photoLibrary, photoDragState, projectsStore. open(_:) sets openProject and loads its
│   │                               photos (via ProjectPhotosLoader) into photoLibrary, resets automationIndex; closeProject()
│   │                               clears openProject/photoLibrary/isReportMode/isAutomationMode/automationIndex.
│   │                               advanceAutomation()/retreatAutomation() clamp automationIndex to [0, lastGroup]. Add app-wide
│   │                               state/features here.
│   ├── MapSlot.swift                One report-map slot: folder, optional group (nested subfolder, e.g. "C12"), isTrash, isInbox.
│   │                               pathComponents/folderURL(in:) resolve where that slot's photos live on disk.
│   ├── Photo.swift                 Identifiable photo (id = stable inode-based ID via Photo.stableID(for:), url).
│   ├── PhotoGroup.swift             One directory's photos: id (slot path, e.g. "C12/T01"), title (shown in the card header),
│   │                               photos: [Photo].
│   ├── PhotoLibrary.swift          @Observable: folderURL, groups: [PhotoGroup] (one per project directory). load(_:folderURL:)
│   │                               sets both; move(groupID:from:to:) reorders photos inside one group via ReorderLayout (no disk
│   │                               writes, never moves photos across groups). Fed by a Project, not a free-standing folder.
│   ├── PhotoGridDragState.swift    @Observable transient drag state for the photo grid: groupID, draggedPhotoID, startIndex,
│   │                               translationX. groupID scopes a drag to the one directory row it started in. Exists because
│   │                               this project cannot use @State (see Key Architecture Decisions) — this class replaces the
│   │                               local @State a SwiftUI-only implementation would use.
│   ├── Project.swift               Codable record of one imported project: id (= its folder name under Application Support),
│   │                               displayName, mapId, folderURL, importedAt. Persisted by ProjectsStore.
│   ├── ProjectMap.swift            A report map: id + ordered [MapSlot]. displaySlots filters out Inbox/Trash — the folders a
│   │                               finished project actually shows, in report order.
│   ├── ProjectsStore.swift         @Observable: projects: [Project]. add(_:)/remove(_:) persist as JSON to
│   │                               ~/Library/Application Support/FastReport/projects.json (loaded on init).
│   └── ReorderLayout.swift         Pure Foundation logic (no SwiftUI/AppKit): targetIndex(...), movingItem(in:from:to:),
│                                   neighborOffset(...). Ported from the old FastReport app's LiveReorderLayout.swift.
├── Services/
│   ├── MapCatalog.swift            The two known report maps (inspection-t24, tendons-retrofit), declared directly in Swift —
│   │                               no JSON/Bundle resources, since this app only reads an already-organized project back in
│   │                               order and never edits or creates maps. map(id:) looks one up by Project.mapId.
│   ├── PhotoFolderLoader.swift     photos(in:) lists supported image files (jpg/jpeg/png/heic/heif/tif/tiff/gif/bmp/webp) in a
│   │                               folder, sorted by localized filename, mapped to Photo. No subfolder recursion, no file moves.
│   ├── ProjectImporter.swift       importZip(at:into:) extracts a .zip (via `/usr/bin/ditto -x -k`, no sandbox/entitlements
│   │                               needed) into ~/Library/Application Support/FastReport/Projects/<name>/, unwraps Finder's
│   │                               extra top-level folder if present (resolveProjectFolder), reads fastreport.json via
│   │                               ProjectMetadataFile, builds a Project and registers it in the given ProjectsStore.
│   ├── ProjectMetadataFile.swift   Codable mapId + displayName read from a project folder's fastreport.json /
│   │                               .fastreport.json (the same file the old FastReport app writes; extra legacy fields ignored).
│   ├── ProjectPhotosLoader.swift   groups(for:) resolves the Project's map via MapCatalog and returns one PhotoGroup per
│   │                               non-empty displaySlot folder, in map order — this is what makes a reopened project show
│   │                               one row per directory, already organized, exactly like the old app's Revisão grid. Falls
│   │                               back to a single flat group scanning the project folder if the mapId isn't in MapCatalog.
│   └── ThumbnailCache.swift        @MainActor NSCache<NSString, NSImage> wrapper. image(for:maxPixelSize:) downsizes via
│                                   ImageIO (CGImageSourceCreateThumbnailAtIndex), cached by path + pixel size.
└── Views/
    ├── MainWindowView.swift       Wraps everything in a GeometryReader: `content` above + StatusBarView below. `content` is
    │                               ProjectView (full window, no sidebar) when state.openProject is set; otherwise the
    │                               NavigationSplitView (sidebar List of AppSection bound to state.selectedSection; detail shows
    │                               HomeView(state:) for .home, SettingsView for .settings, empty otherwise). StatusBarView shows
    │                               project name + photo count when a project is open, else the window size ("W × H px").
    ├── Components/
    │   ├── StatusBarView.swift     Classic bottom status bar. StatusBarView { content } = top divider + 22pt bar (.bar material,
    │   │                           11pt secondary text); StatusBarItem(icon:, text) = one cell with a trailing vertical divider.
    │   │                           Add more cells inside the StatusBarView closure in MainWindowView.
    │   ├── IconActionButtonStyle.swift  Reusable ButtonStyle for small icon buttons. Uses configuration.isPressed only (no @State):
    │   │                           on press, shrinks (scaleEffect 0.80) and flashes a tinted rounded background (tint param,
    │   │                           default .primary). Gives visible click feedback.
    │   └── PhotoDragSourceView.swift  NSViewRepresentable (PhotoDragNSView: NSView, NSDraggingSource) overlaid on each thumbnail.
    │                               Takes isReportMode (threaded down from AppState via ProjectView → ...). Outside report mode,
    │                               mouseDragged only calls onReorderPreview(translationX) (live grid reorder preview) — it never
    │                               starts a native drag session, so a photo can never be dragged out of the window/app while
    │                               organizing. In report mode, the same gesture never reorders: past the 4px threshold it goes
    │                               straight to beginDraggingSession(...), exporting the file to another app via PhotoPasteboardWriter
    │                               (NSPasteboardWriting: .fileURL, NSFilenamesPboardType, and the file's UTType). mouseUp commits
    │                               the reorder (onReorderCommit) when no external session started, or calls onClick on a plain
    │                               click. Ported/adapted from the old FastReport app's ExternalFileDragOverlay.swift.
    ├── Home/
    │   └── HomeView.swift          HOME SCREEN. Takes AppState. Just renders ProjectListView — routing between the list and an
    │                               open project happens one level up, in MainWindowView, so the sidebar disappears too.
    ├── Projects/
    │   ├── ProjectListView.swift   Project list screen. Toolbar "Importar projeto (.zip)…" opens NSOpenPanel filtered to
    │   │                           .zip, runs ProjectImporter.importZip(at:into:), then state.open(_:) the result (NSAlert on
    │   │                           failure). Tapping a row also calls state.open(_:). Empty state when projectsStore is empty.
    │   └── ProjectView.swift       One project's screen, shown full-window (see MainWindowView): back-chevron toolbar
    │                               (state.closeProject()) + project.displayName + reportModeToggle (toggles state.isReportMode,
    │                               pill button "Organizar fotos" ↔ "Modo de relatório") + automationModeToggle (🤖, only shown
    │                               while isReportMode is on; toggles state.isAutomationMode, resets automationIndex), then
    │                               ProjectPhotoBoardView(library: state.photoLibrary, dragState: state.photoDragState,
    │                               isReportMode:, isAutomationMode:, automationIndex:, onAdvanceAutomation:, onRetreatAutomation:).
    ├── Photos/
    │   ├── ProjectPhotoBoardView.swift  The project screen's body. Normally a vertical ScrollView of PhotoGroupCard, one per
    │   │                           state.photoLibrary.groups entry (one per directory — "General 3", "T1 7", ...). Each card is
    │   │                           a rounded, bordered container with a title + count header above a PhotoGroupStripView.
    │   │                           When isAutomationMode is on, renders automationBody instead: only library.groups[automationIndex]
    │   │                           as a single PhotoGroupCard, plus "Anterior"/"Próximo" buttons (⌘←/⌘→ keyboard shortcuts, each
    │   │                           disabled at its end of the list) calling onRetreatAutomation/onAdvanceAutomation — one
    │   │                           directory at a time, for driving via an external click-automation/macro app.
    │   ├── PhotoGroupStripView.swift  One directory's row: horizontal scroll strip of PhotoThumbnailView for one PhotoGroup's
    │   │                           photos. Takes isReportMode (passed to each PhotoThumbnailView). Computes each neighbor's shift
    │   │                           live during a drag via ReorderLayout, mirroring the old app's per-folder LiveReorderStrip but
    │   │                           driven by PhotoGridDragState instead of local @State. Drags never leave their own group; on
    │   │                           commit calls library.move(groupID:from:to:). onReorderCommit/onReorderCancel run inside
    │   │                           withAnimation(.spring(...)) and the cell applies a second .animation(value: isDragged) (on top
    │   │                           of the existing one keyed on currentTargetIndex) so pick-up/drop/settle are animated while the
    │   │                           live 1:1 pointer tracking during an active drag stays unanimated.
    │   └── PhotoThumbnailView.swift  One photo cell: NSImage via ThumbnailCache, rounded background, overlaid with
    │                               PhotoDragSourceView(isReportMode:) for the mode-gated reorder/export gesture.
    └── Settings/
        └── SettingsView.swift      SETTINGS SCREEN. Single "Atualizações" card: current version (CFBundleShortVersionString) +
                                     "Verificar atualizações" button (state.updater.checkForUpdates()).
```

---

## Key Architecture Decisions

| Decision | Reason |
|---|---|
| `@Observable` instead of `ObservableObject` | `ObservableObject` uses `@Published` which works, but `@Observable` is the modern pattern and ObservationMacros plugin IS available in Command Line Tools |
| No `@State`, `@Binding`, `@Environment` | SwiftUIMacros plugin is missing from Command Line Tools (only available with full Xcode). All local state lives in `@Observable` classes. Bindings use `Binding(get:set:)` |
| `NSWindow` instead of `WindowGroup` | The app is started from a custom `main` with AppKit; the window is created manually |
| `NSHostingView` bridge | Hosts SwiftUI views inside the AppKit NSWindow. SwiftUI handles all UI rendering |
| `.regular` activation policy | Dock icon shown while the app runs |
| `swift-tools-version:6.2` | Required for `.macOS(.v26)` platform target |
| `.swiftLanguageMode(.v5)` | Avoids Swift 6 strict concurrency requirements while using 6.2 toolchain |
| `fswatch` for hot reload | Lightweight file watcher (Homebrew). Monitors Sources/ and triggers rebuild+relaunch |
| Sparkle for auto-update | De facto standard for non-App-Store macOS apps. Handles update checks, EdDSA-verified downloads, and silent install (SUAutomaticallyUpdate) |
| GitHub Releases "latest" redirect as feed URL | `releases/latest/download/appcast.xml` never changes, so Info.plist's SUFeedURL is static even though old releases get deleted on every tag push |
| Ad-hoc codesign only (no Developer ID yet) | No Apple Developer account configured. First launch after install/update shows a Gatekeeper warning until a Developer ID + notarization is added |

---

## Build & Run

```bash
swift build                    # compile
.build/debug/FastReport        # run directly
bash dev.sh                    # hot reload (watch + rebuild + relaunch)

# Release packaging (normally done by .github/workflows/release.yml on a tag push):
swift build -c release
APP_VERSION=1.0.0 APP_OWNER=<owner> APP_REPO=<repo> SPARKLE_PUBLIC_KEY=<key> bash Scripts/package_app.sh
SPARKLE_PRIVATE_KEY=<key> bash Scripts/build_appcast.sh   # signs dist/*.zip, writes dist/appcast.xml

# One-time, local only (writes to your login Keychain, never run in CI):
bash Scripts/generate_sparkle_keys.sh
```

## Conventions

- **One responsibility per file** — each file contains a single struct/class/enum
- **Views** — SwiftUI views go in Views/
- **Models** — observable state and data types go in Models/
- **No comments in code** — code is self-documenting; this map file is the reference
