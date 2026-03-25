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
├── Models/
│   ├── ICSEvent.swift      # Modèle principal (titre, description)
│   └── ICSOccurrence.swift # Une occurrence (dates, lieu)
├── Views/
│   ├── ContentView.swift   # Layout principal
│   ├── EventMetadataForm.swift
│   ├── OccurrenceList.swift
│   └── OccurrenceRow.swift
└── Services/
    └── ICSGenerator.swift  # Génération du fichier .ics (RFC 5545)
```

## Pièges connus SwiftUI / macOS

- À compléter au fil du développement

## Règles spécifiques

- Commentaires et noms de variables en français
- Pas de dépendances externes (SPM) — Swift pur uniquement
- Tester l'export sur Calendrier Apple à chaque milestone
