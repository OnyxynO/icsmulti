# ICSMulti

Créez des fichiers de calendrier `.ics` avec plusieurs événements et plusieurs lieux — en quelques secondes.

## À quoi ça sert ?

Vous organisez des cours, des concerts, un festival ou une tournée ? Vous avez besoin de publier un calendrier sur votre site web pour que vos participants puissent l'ajouter en un clic à leur calendrier (Google Calendar, Apple Calendrier, Outlook…) ?

ICSMulti vous permet de créer un seul fichier `.ics` contenant plusieurs événements, chacun avec son propre titre, ses notes et son lieu.

**Exemple :** une tournée de 8 concerts dans 8 villes → un seul fichier `.ics` à mettre en téléchargement sur votre site.

## Téléchargement

👉 [Télécharger ICSMulti-1.0.dmg](https://github.com/OnyxynO/icsmulti/releases/latest)

**Configuration requise :** macOS 26 ou supérieur

## Installation

1. Ouvrez le fichier `.dmg` téléchargé
2. Glissez **ICSMulti** dans le dossier **Applications**
3. Au premier lancement, macOS bloque l'app car elle n'est pas signée. Deux options :

**Option A — Réglages Système** *(recommandée)*
- Essayez d'ouvrir l'app une première fois → macOS affiche un refus
- Ouvrez **Réglages Système → Confidentialité et sécurité**
- Cliquez sur **"Ouvrir quand même"** en bas de la section Sécurité

**Option B — Terminal**
```bash
xattr -d com.apple.quarantine /Applications/ICSMulti.app
```
Puis ouvrez l'app normalement. Cette commande supprime uniquement la restriction de quarantaine sur ICSMulti, sans modifier vos réglages de sécurité.

## Utilisation

1. Ajoutez vos événements avec le bouton **+**
2. Pour chaque événement : renseignez le **titre**, une **description** facultative, les dates de début et de fin, et le lieu
   - Le champ lieu propose des suggestions automatiques
   - Le bouton carte 🗺 permet de choisir un lieu directement sur une carte
3. Cliquez sur **Exporter .ics** et enregistrez le fichier
4. Mettez ce fichier en téléchargement sur votre site — vos participants cliquent dessus et les événements s'ajoutent à leur calendrier

## Fonctionnalités

- Autant d'événements que vous voulez, chacun avec son propre titre, ses notes et son lieu
- Événements sur une journée entière ou avec horaires précis
- Rappels optionnels (15 min, 1h, 1 jour avant…)
- Autocomplétion des adresses
- Historique de vos 20 derniers exports
- Format standard RFC 5545 — compatible avec tous les calendriers

## Écosystème ICSMulti

| Projet | Stack | Description |
|---|---|---|
| [icsmulti](https://github.com/OnyxynO/icsmulti) | Swift 6 + SwiftUI | App macOS native — multi-occurrences, MapKit, export DMG |
| [icsmulti-web](https://github.com/OnyxynO/icsmulti-web) | Next.js 16 + TypeScript | Web app + API REST + widget intégrable |

## Licence

MIT
