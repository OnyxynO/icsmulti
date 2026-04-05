# ICSMulti — CLAUDE.md

@../GUIDELINES_PROJETS.md

## Contexte projet

App macOS native (SwiftUI) pour créer des fichiers `.ics` multi-dates avec lieux variables.
Distribution : `.dmg` non signé via GitHub Releases.

## Stack

- **Langage** : Swift 6
- **UI** : SwiftUI (macOS 14+ Sonoma minimum)
- **Génération ICS** : Swift pur, RFC 5545, pas de dépendance externe
- **Export** : `NSSavePanel` natif macOS
- **Distribution** : Archive Xcode → `.dmg` → GitHub Releases

## Structure du projet Xcode

```
ICSMulti/
├── ICSMultiApp.swift       # Point d'entrée @main
├── ContentView.swift       # Vues principales : ContentView (toolbar, export, chargement historique)
├── Models/
│   ├── EvenementStore.swift  # @Observable — liste des occurrences
│   └── ICSOccurrence.swift   # struct — titre, notes, dateDebut, dateFin, lieu, touteLaJournee
├── Views/
│   ├── ListeOccurrences.swift  # Liste + ajout + duplication + état vide
│   ├── LigneOccurrence.swift   # Ligne occurrence : titre, notes, dates, lieu, rappel
│   ├── HistoriqueSheet.swift   # Sheet historique des 20 derniers exports
│   └── MapPickerSheet.swift    # Sheet sélection de lieu sur carte
└── Services/
    ├── ICSGenerator.swift            # Génération du fichier .ics (RFC 5545)
    ├── HistoriqueService.swift       # Historique exports UserDefaults (clé v2)
    └── RechercheAdresseService.swift # Autocomplétion via MKLocalSearchCompleter + historique UserDefaults
ICSMultiTests/
└── ICSGeneratorTests.swift  # 24 tests Swift Testing (structure, CRLF, échappement, folding, VALARM)
```

**Note architecture** : `ContentView.swift` orchestre l'app (toolbar, export, chargement historique).
Les vues de liste et de ligne sont dans `Views/`. Les nouveaux fichiers Swift doivent être
ajoutés manuellement au `.pbxproj` via Xcode (glisser dans le navigateur de projet).

## État d'avancement

- **Phase 1** ✅ — Modèles + ICSGenerator (RFC 5545, CRLF, Europe/Paris)
- **Phase 2** ✅ — UI SwiftUI complète (formulaire, liste occurrences, validation)
- **Phase 3** ✅ — Export NSSavePanel + gestion erreurs
- **Phase 4** ✅ — Corrections et améliorations (session 2)
  - Sandbox : `ENABLE_USER_SELECTED_FILES = readwrite` pour NSSavePanel
  - Validation : fin >= début (autorise les événements sans durée)
  - Événements journée entière (`touteLaJournee`, format `VALUE=DATE`, fin J+1 RFC 5545)
  - Événements multi-jours (DatePicker date+heure sur début ET fin)
  - Suppression sécurisée : `Binding(get:set:)` par UUID (plus d'accès par index)
  - Défensif : guards sur indices tableau, échappement RFC 5545 (`,` `;` `\` `\n`)
  - Conformité RFC 5545 : line folding à 75 octets
  - Navigation clavier : focus auto sur Titre, Tab/Return entre champs, ⌘N / ⌘S
- **Phase 5** ✅ — Autocomplétion adresse + lien Maps (session 3)
  - `RechercheAdresseService` : `MKLocalSearchCompleter` déclenché dès 3 caractères
  - Région par défaut centrée sur la France métropolitaine
  - Historique des lieux récents via `UserDefaults` (max 20, dédupliqué)
  - Dropdown suggestions (max 5) affiché sous le champ lieu
  - Bouton "map" → ouvre l'adresse dans Apple Plans (`maps://?q=...`)
  - `LigneOccurrence` extrait dans `Views/LigneOccurrence.swift`
- **Phase 6** ✅ — Refactoring titre/notes par occurrence (session 4)
  - `titre` et `notes` déplacés de `EvenementStore` vers `ICSOccurrence`
  - `FormMetadonnees.swift` supprimé — champs intégrés dans `LigneOccurrence`
  - `peutExporter` vérifie que toutes les occurrences ont un titre non vide
  - `HistoriqueService` : nouvelle clé UserDefaults `v2` (ancien historique effacé au premier lancement)
  - Vocabulaire UI : "occurrence" → "événement"
- **Phase 7** ✅ — Tests unitaires, CI/CD et corrections RFC 5545 (session 5)
  - 24 tests Swift Testing sur `ICSGenerator` (structure, CRLF, DTSTAMP, échappement, line folding, VALARM, champs optionnels)
  - `DTSTAMP` obligatoire ajouté dans chaque VEVENT (RFC 5545 §3.6.1)
  - `DispatchQueue.main.asyncAfter` remplacé par `.task { }` annulable dans `ContentView`
  - `@MainActor` redondant supprimé sur `exporter()` (implicite via build settings)
  - Workflow GitHub Actions CI (build + tests à chaque push/PR sur `main`)
- **Reste** : suite navigation Tab dans les occurrences

## Pièges connus SwiftUI / macOS

- **xcode-select** : doit pointer vers `Xcode.app`, pas `CommandLineTools`.
  Si `xcodebuild` échoue avec "not a developer tool", corriger avec :
  `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

- **Nouveaux fichiers Swift** : créer un fichier hors Xcode ne l'ajoute pas au projet.
  Il faut soit l'ajouter via Xcode (glisser dans le navigateur), soit éditer le `.pbxproj`.
  Stratégie adoptée : regrouper les vues connexes dans un même fichier avec des `// MARK:`.

- **SourceKit vs compilateur** : les erreurs "Cannot find X in scope" dans l'IDE peuvent être
  des faux positifs si le build `xcodebuild` réussit. Le compilateur voit tous les fichiers du
  projet, SourceKit peut analyser un fichier isolément.

- **`@Bindable`** : nécessaire dans les sous-vues pour obtenir des `Binding` depuis un type
  `@Observable`. Syntaxe : `@Bindable var store: EvenementStore` + `$store.occurrences`.

- **App Sandbox + NSSavePanel** : le projet a `ENABLE_APP_SANDBOX = YES` par défaut.
  Sans `ENABLE_USER_SELECTED_FILES = readwrite` dans le `.pbxproj`, NSSavePanel crashe
  avec `EXC_BREAKPOINT` à l'initialisation. Le modifier dans les deux configs (Debug + Release).

- **`open App.app` depuis le terminal** : crée une deuxième instance → deux icônes Dock,
  conflit de session avec Xcode. Toujours lancer via Xcode ⌘R uniquement.

- **XcodeBuildMCP suggère iOS** : ignorer les suggestions "iPhone 17" / iOS Simulator —
  ce projet cible macOS. Toujours utiliser :
  `xcodebuild -project X.xcodeproj -scheme X -destination 'platform=macOS' build`

- **ForEach + suppression** : `ForEach($array) { $item in ... }` + suppression = crash
  (binding devient invalide). Pattern correct : `Binding(get:set:)` par UUID stable.
  ```swift
  ForEach(store.occurrences) { occurrence in
      LigneOccurrence(occurrence: Binding(
          get: { store.occurrences.first { $0.id == occurrence.id } ?? occurrence },
          set: { nv in
              guard let i = store.occurrences.firstIndex(where: { $0.id == occurrence.id }) else { return }
              store.occurrences[i] = nv
          }
      )) { store.occurrences.removeAll { $0.id == occurrence.id } }
  }
  ```

- **`description` est un nom réservé** : `@Observable class` avec `var description` masque
  `CustomStringConvertible.description`. Renommer en `notes`, `descriptif`, etc.

- **Swift 6 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** : toute l'app est implicitement
  `@MainActor`. Annoter `@MainActor` sur des méthodes individuelles est redondant.

- **RFC 5545 line folding** : les lignes > 75 octets doivent être repliées (CRLF + espace).
  Sans ça, certains clients calendrier rejettent le fichier. Implémenter `replierLigne()`.

- **RFC 5545 échappement** : SUMMARY, DESCRIPTION, LOCATION doivent échapper
  `\` → `\\`, `;` → `\;`, `,` → `\,`, `\n` → `\n`. Ordre : `\` en premier.

- **CLGeocoder déprécié macOS 26** : toute l'API CoreLocation de géocodage est dépréciée.
  Migrer vers MapKit : `MKGeocodingRequest(addressString:)`, `MKReverseGeocodingRequest(location:)`,
  `item.location.coordinate` (plus `item.placemark.coordinate`), `item.address?.fullAddress`.
  Stocker la requête en `@State` pour pouvoir appeler `.cancel()`. `import CoreLocation` inutile
  (réexporté par MapKit).

- **`.onDelete` inexistant sur macOS** : le swipe-to-delete est un geste iOS. Sur macOS,
  `.onDelete` nécessite un mode édition explicite — pas intuitif pour une app utilitaire.
  Préférer un bouton trash visible par ligne.

- **App qui ne se ferme pas avec la croix rouge** : comportement macOS par défaut — fermer
  la dernière fenêtre ne quitte pas l'app. Pour une app utilitaire sans gestion de documents :
  ```swift
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  class AppDelegate: NSObject, NSApplicationDelegate {
      func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  }
  ```

- **`let id = UUID()` incompatible avec Codable** : `let id: UUID = UUID()` empêche la
  synthèse automatique de `Codable` (le décodeur ne peut pas assigner une `let` avec
  initializer par défaut). Solution : `let id: UUID` + `init(id: UUID = UUID(), ...)` explicite.

- **Modification de `@Binding` depuis un callback déclenche `onChange`** : écrire
  `occurrence.lieu = adresse` dans un bouton de suggestion relance `.onChange(of: occurrence.lieu)`.
  Utiliser un flag `selectionEnCours = true` avant la modification, vérifié et remis à `false`
  dans le `onChange`. Même problème avec `onDismiss` d'une sheet qui écrit dans un binding.

- **`Task` plutôt que `DispatchQueue.asyncAfter` pour les timers UI** : `asyncAfter` n'est
  pas annulable. Si le timer peut être relancé (ex: feedback qui se réaffiche), utiliser `Task`
  avec `tache?.cancel()` avant de relancer.

- **DatePicker envoie des valeurs intermédiaires** : ne pas déclencher de transformations lourdes
  (tri, réorganisation) dans le `set:` d'un Binding lié à un DatePicker. Réserver ces
  transformations aux actions ponctuelles stables (ajout, duplication).

- **Icône Release vs Debug** : le format "single 1024×1024" peut ne pas fonctionner en Release.
  Fournir toutes les tailles explicitement (16, 32, 64, 128, 256, 512, 1024) dans `Contents.json`.
  Convertir le PNG source via `sips -s format png` avant redimensionnement si nécessaire.

- **Navigation Tab dans les TextFields macOS — problème non résolu** :
  Tab est intercepté par AppKit avant que SwiftUI le voie. Ni `.onSubmit` (Return seulement),
  ni `.onKeyPress(.tab)` (non intercepté par AppKit), ni `NSEvent.addLocalMonitorForEvents`
  (monitor global, complexe et fragile) ne fonctionnent de façon fiable pour router Tab
  depuis un TextField vers un Button.
  Pistes non encore essayées : `NSViewRepresentable` avec un NSTextField personnalisé et
  override de `keyDown`, ou accepter que Tab ne fonctionne pas et documenter ⌘N comme
  raccourci alternatif pour "Ajouter une occurrence" (déjà en place).

## À faire

- **CI/CD** : le workflow `.github/workflows/ci.yml` cible `macos-26` + `Xcode_26.3` (GA depuis février 2026). Le projet nécessite macOS 26+ (APIs `MKReverseGeocodingRequest`, etc.).
- **Navigation Tab** : suite navigation Tab dans les occurrences (problème non résolu, voir pièges connus)

## Règles spécifiques

- Commentaires et noms de variables en français
- Pas de dépendances externes (SPM) — Swift pur uniquement
- Tester l'export sur Calendrier Apple à chaque milestone
- Utiliser context7 (`/websites/developer_apple_swiftui`) avant tout code SwiftUI non trivial
