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
│   ├── EvenementStore.swift  # @Observable — titre, description, occurrences
│   └── ICSOccurrence.swift   # struct — dateDebut, dateFin, lieu
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
- **Reste** : icône app + `.dmg`

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

## Règles spécifiques

- Commentaires et noms de variables en français
- Pas de dépendances externes (SPM) — Swift pur uniquement
- Tester l'export sur Calendrier Apple à chaque milestone
