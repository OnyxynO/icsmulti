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
├── ContentView.swift       # Toutes les vues : ContentView, FormMetadonnees,
│                           # ListeOccurrences, LigneOccurrence (MARK séparés)
├── Models/
│   ├── EvenementStore.swift  # @Observable — titre, notes, occurrences
│   └── ICSOccurrence.swift   # struct — dateDebut, dateFin, lieu, touteLaJournee
└── Services/
    └── ICSGenerator.swift  # Génération du fichier .ics (RFC 5545)
```

**Note architecture** : les sous-vues sont dans `ContentView.swift` (pas dans un dossier Views/).
Raison : les nouveaux fichiers Swift hors Xcode ne s'ajoutent pas automatiquement au `.pbxproj` —
il faudrait l'éditer manuellement ou passer par Xcode. Pour éviter ça, tout est dans un seul fichier
avec des `// MARK:` pour l'organisation.

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
- **Reste** : suite navigation (Tab dans occurrences), lien Maps pour le lieu, stabilisation UI, icône app + `.dmg`

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
  `@Observable`. Syntaxe : `@Bindable var store: EvenementStore` + `$store.titre`.

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

## Règles spécifiques

- Commentaires et noms de variables en français
- Pas de dépendances externes (SPM) — Swift pur uniquement
- Tester l'export sur Calendrier Apple à chaque milestone
- Utiliser context7 (`/websites/developer_apple_swiftui`) avant tout code SwiftUI non trivial
