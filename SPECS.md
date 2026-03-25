# ICSMulti — Spécifications

## Fonctionnel

### Cas d'usage principal

L'utilisateur veut créer un fichier `.ics` pour un événement qui se répète sur plusieurs dates avec des lieux différents (cours, festival, tournée...).

### Flux utilisateur

1. L'utilisateur ouvre l'app
2. Il saisit les métadonnées de l'événement (titre, description optionnelle)
3. Il ajoute autant d'occurrences que nécessaire via le bouton "Ajouter une occurrence"
4. Pour chaque occurrence : date, heure de début, heure de fin, lieu
5. Il clique sur "Exporter .ics"
6. Une boîte de dialogue native macOS s'ouvre pour choisir l'emplacement de sauvegarde
7. Le fichier `.ics` est généré et sauvegardé
8. L'utilisateur importe le fichier dans Calendrier Apple (double-clic ou glisser-déposer)

### Interface

```
┌─────────────────────────────────────────────┐
│  Titre de l'événement  [___________________]│
│  Description           [___________________]│
├─────────────────────────────────────────────┤
│  Occurrences                                │
│  ┌─────────────────────────────────────┐   │
│  │ 25 mars 2026  14:00 → 16:00  Paris  │ ✕ │
│  │ 01 avr. 2026  14:00 → 16:00  Lyon   │ ✕ │
│  │ 08 avr. 2026  09:00 → 12:00  Nantes │ ✕ │
│  └─────────────────────────────────────┘   │
│  [+ Ajouter une occurrence]                 │
├─────────────────────────────────────────────┤
│                      [Exporter .ics]        │
└─────────────────────────────────────────────┘
```

### Règles métier

- Titre obligatoire (le bouton export est désactivé si vide)
- Au moins une occurrence pour pouvoir exporter
- Heure de fin > heure de début (validation à l'export)
- Lieu optionnel par occurrence
- Fuseau horaire : Europe/Paris par défaut (pas de réglage utilisateur en v1)

---

## Technique

### Modèle de données

```swift
// Une occurrence de l'événement
struct ICSOccurrence: Identifiable {
    let id: UUID = UUID()
    var dateDebut: Date
    var dateFin: Date
    var lieu: String
}

// L'événement principal
@Observable
class EvenementStore {
    var titre: String = ""
    var description: String = ""
    var occurrences: [ICSOccurrence] = []
}
```

### Format ICS généré (RFC 5545)

```
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//ICSMulti//FR
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:<uuid>@icsmulti
DTSTART;TZID=Europe/Paris:20260325T140000
DTEND;TZID=Europe/Paris:20260325T160000
SUMMARY:Titre de l'événement
DESCRIPTION:Description optionnelle
LOCATION:Paris
END:VEVENT
BEGIN:VEVENT
UID:<uuid>@icsmulti
...
END:VEVENT
END:VCALENDAR
```

Chaque occurrence = un bloc `VEVENT` distinct. Pas de `RRULE` (récurrence régulière) — dates irrégulières avec lieux différents.

### Export

- `NSSavePanel` avec extension `.ics` forcée
- Écriture du fichier en UTF-8

### Configuration Xcode

- Target : macOS 14.0+
- Bundle ID : `fr.setievant.icsmulti`
- Signing : None (distribution hors App Store)

---

## Phases de développement

### Phase 1 — Modèle + génération ICS (pas d'UI)
- Modèles `ICSOccurrence` et `EvenementStore`
- `ICSGenerator` qui produit un fichier `.ics` valide
- Tester l'import dans Calendrier Apple

### Phase 2 — Interface SwiftUI
- Formulaire métadonnées
- Liste des occurrences avec ajout/suppression
- Validation (titre requis, au moins une occurrence)

### Phase 3 — Export et finitions
- Bouton export + `NSSavePanel`
- Gestion des erreurs
- Icône app + `.dmg`

---

## Questions ouvertes / décisions reportées

- v2 : support multi-fuseaux horaires ?
- v2 : import d'un `.ics` existant pour modifier ?
