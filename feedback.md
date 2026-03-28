# ICSMulti — Feedback & leçons apprises

## Résumé du projet

App macOS native (SwiftUI, Swift 6) pour créer des fichiers `.ics` multi-occurrences avec lieux variables. 12 fichiers Swift, ~1 090 lignes de code, zéro dépendance externe.

---

## Problèmes rencontrés et solutions

### 1. CLGeocoder déprécié (macOS 26)

**Symptôme** : 5 warnings au build — `CLGeocoder`, `reverseGeocodeLocation`, `geocodeAddressString`, `cancelGeocode`, `.placemark` tous dépréciés.

**Cause** : Apple a migré le géocodage de CoreLocation vers MapKit dans macOS 26.

**Solution** :
- `CLGeocoder` → `MKGeocodingRequest(addressString:)` + `MKReverseGeocodingRequest(location:)`
- `geocoder.cancelGeocode()` → `requete.cancel()` (référence stockée en `@State`)
- `CLPlacemark.subThoroughfare` etc. → `MKMapItem.address?.fullAddress`
- `item.placemark.coordinate` → `item.location.coordinate`
- `import CoreLocation` supprimé (réexporté par MapKit)

**Leçon** : Toujours vérifier les deprecation warnings, même si le build passe. Les nouvelles API MapKit sont plus simples (MKMapItem unifié au lieu de CLPlacemark).

---

### 2. Double validation des suggestions d'adresse

**Symptôme** : Cliquer une suggestion d'adresse dans la dropdown forçait à cliquer deux fois pour la valider.

**Cause** : `occurrence.lieu = adresse` dans le bouton de suggestion déclenchait `.onChange(of: occurrence.lieu)` qui remettait `afficherSuggestions = true` (car l'adresse > 3 caractères).

**Séquence** :
1. Clic suggestion → `occurrence.lieu = "Rue de Rivoli, Paris"` → `afficherSuggestions = false`
2. `onChange` se déclenche → `afficherSuggestions = "Rue de Rivoli, Paris".count >= 3` → `true`
3. La dropdown se réaffiche

**Solution** : Flag `selectionEnCours` mis à `true` avant d'écrire `occurrence.lieu`. Le `onChange` vérifie ce flag, le remet à `false` et skip la logique de recherche.

**Même problème avec MapPickerSheet** : le binding de retour déclenchait aussi `onChange`. Solution : `onDismiss: { selectionEnCours = true }` sur la `.sheet`.

**Leçon** : En SwiftUI, modifier un `@Binding` depuis un callback déclenche systématiquement les `onChange` associés. Toujours prévoir un mécanisme de garde (flag, debounce) pour les modifications programmatiques.

---

### 3. Tri auto pendant l'édition DatePicker

**Symptôme** : Trier les occurrences à chaque changement de `dateDebut` dans le `set:` du Binding causait des sauts visuels pendant l'interaction avec le DatePicker.

**Cause** : Le DatePicker envoie des valeurs intermédiaires pendant la sélection. Trier à chaque valeur déplaçait la ligne en cours d'édition.

**Solution** : Retirer le tri du `set:` Binding. Ne trier que sur les actions ponctuelles (ajout, duplication) où le contexte est clair.

**Leçon** : Ne pas réagir à chaque micro-changement d'un contrôle interactif. Réserver les transformations lourdes (tri, réorganisation) aux moments stables (validation, ajout).

---

### 4. `.onDelete` inexistant sur macOS

**Symptôme** : Le swipe-to-delete dans la `List` de l'historique ne fonctionnait pas.

**Cause** : `.onDelete` est un geste iOS (swipe). Sur macOS, il nécessite un mode édition ou la touche Delete avec sélection — pas intuitif.

**Solution** : Bouton trash explicite par ligne, toujours visible.

**Leçon** : SwiftUI n'est pas identique entre iOS et macOS. Toujours vérifier que les interactions fonctionnent sur la plateforme cible. Sur macOS, préférer les boutons explicites aux gestes.

---

### 5. Position instable du bouton "Ajouter"

**Symptôme** : Le bouton "Ajouter une occurrence" était centré quand la liste était vide (à cause du `ContentUnavailableView`), puis sautait à gauche quand des occurrences apparaissaient.

**Solution** : Déplacer le bouton dans le header (HStack avec `Spacer()` + bouton à droite). Position fixe quel que soit l'état de la liste.

**Leçon** : Les éléments d'action récurrents (boutons d'ajout) doivent avoir une position fixe dans la mise en page, indépendante du contenu conditionnel.

---

### 6. Icône app absente du DMG

**Symptôme** : Le `.app` dans le DMG n'avait pas d'icône. Le build Debug la montrait, mais pas le Release.

**Causes multiples** :
- Le DMG initial a été créé avant l'ajout de l'icône à l'asset catalog
- Le format "single 1024x1024" du `Contents.json` ne fonctionnait pas en Release
- Le PNG source avait un format que `sips` ne pouvait pas redimensionner directement (nécessitait une conversion préalable via `sips -s format png`)

**Solution** :
- Convertir le PNG source via `sips -s format png` avant redimensionnement
- Fournir toutes les tailles explicitement (16, 32, 64, 128, 256, 512, 1024)
- `Contents.json` multi-tailles avec les bons `filename`/`scale`/`size`
- Recréer le DMG depuis le build Release

**Leçon** :
- L'approche "single size" d'Xcode 14+ ne fonctionne pas de manière fiable dans tous les contextes de build. Le multi-tailles explicite est plus sûr.
- Toujours vérifier le contenu du `.app` (`Contents/Resources/*.icns`) avant de créer un DMG.
- Un PNG "valide" visuellement peut avoir un format interne incompatible avec `sips`. Passer par une conversion explicite.

---

### 7. L'app ne se ferme pas avec la croix rouge

**Symptôme** : Cliquer le bouton rouge de fermeture masquait la fenêtre mais l'app restait dans le Dock.

**Cause** : Comportement par défaut de macOS — fermer la dernière fenêtre ne quitte pas l'app (contrairement à Windows/Linux).

**Solution** : `NSApplicationDelegate` avec `applicationShouldTerminateAfterLastWindowClosed → true`.

```swift
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
// ...
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
```

**Leçon** : SwiftUI masque beaucoup de comportements AppKit par défaut. Pour une app utilitaire (pas un éditeur de documents), il faut explicitement demander la fermeture sur dernière fenêtre.

---

### 8. `ICSOccurrence` — `let id = UUID()` incompatible avec Codable

**Symptôme** : `let id: UUID = UUID()` avec synthèse automatique de `Codable` ne compile pas car le décodeur ne peut pas assigner une propriété `let` avec un initializer par défaut.

**Solution** : Remplacer par `let id: UUID` + `init(id: UUID = UUID(), ...)` explicite. Tous les call sites existants continuent de fonctionner grâce au paramètre par défaut.

**Leçon** : En Swift, `let prop = valeur` dans une struct empêche la synthèse Codable. Utiliser `let prop: Type` + init avec défaut est la bonne approche pour les identifiants stables + sérialisables.

---

### 9. `ForEach` + suppression = crash si binding par index

**Symptôme** (découvert en phase 2) : `ForEach($array) { $item in ... }` + suppression d'un élément = crash car le binding devient invalide.

**Solution** : Pattern `Binding(get:set:)` par UUID stable au lieu d'un binding direct sur l'index.

```swift
ForEach(store.occurrences) { occurrence in
    LigneOccurrence(occurrence: Binding(
        get: { store.occurrences.first { $0.id == occurrence.id } ?? occurrence },
        set: { guard let i = store.occurrences.firstIndex(where: { $0.id == occurrence.id }) else { return }
               store.occurrences[i] = $0 }
    ))
}
```

**Leçon** : Ne jamais utiliser `ForEach($array)` si des éléments peuvent être supprimés pendant l'itération. Le pattern UUID-based Binding est le seul fiable.

---

### 10. Feedback export avec annulation de Timer

**Problème potentiel** : Si l'utilisateur exporte deux fois rapidement, le premier `DispatchQueue.asyncAfter` pourrait masquer le feedback du second export.

**Solution** : Utiliser `Task` + `.cancel()` au lieu de `DispatchQueue.asyncAfter`.

```swift
tacheDisparition?.cancel()
tacheDisparition = Task {
    try? await Task.sleep(for: .seconds(2))
    guard !Task.isCancelled else { return }
    exportReussi = false
}
```

**Leçon** : `DispatchQueue.asyncAfter` n'est pas annulable. Pour tout timer UI qui peut être interrompu/relancé, préférer `Task` avec cancellation.

---

## Bonnes pratiques confirmées

| Pratique | Détail |
|----------|--------|
| **PBXFileSystemSynchronizedRootGroup** | Les nouveaux fichiers Swift ajoutés dans le dossier sont auto-compilés, pas besoin de toucher au `.pbxproj` |
| **`@Observable` + `@Bindable`** | Pattern propre pour SwiftUI : le store est `@Observable`, les sous-vues utilisent `@Bindable` pour obtenir des `$bindings` |
| **RFC 5545 line folding** | Indispensable — sans ça, certains clients calendrier rejettent le fichier |
| **UserDefaults pour persistance légère** | Adapté pour historique (20 entrées × ~200 octets/occurrence = ~80 Ko max) |
| **Commentaires et noms en français** | Cohérent sur tout le projet, aide à la lisibilité pour le contexte francophone |

---

## Architecture finale

```
ICSMultiApp (27 lignes)
 └── ContentView (142 lignes) — orchestrateur
      ├── FormMetadonnees (33 lignes) — titre + notes
      ├── ListeOccurrences (109 lignes) — ajout, duplication, tri
      │    └── LigneOccurrence (161 lignes) — édition complète
      │         ├── RechercheAdresseService (85 lignes) — autocomplétion
      │         └── MapPickerSheet (231 lignes) — sélection carte
      └── HistoriqueSheet (94 lignes) — restauration
           └── HistoriqueService (63 lignes) — persistance

Modèles : ICSOccurrence (22 lignes) + EvenementStore (16 lignes)
Génération : ICSGenerator (107 lignes)

Total : ~1 090 lignes Swift, 0 dépendance externe
```

---

## Stack technique

| Composant | Choix | Raison |
|-----------|-------|--------|
| Langage | Swift 6 | Dernière version, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| UI | SwiftUI (macOS 26+) | Natif, déclaratif, pas de storyboard |
| Carte | MapKit (Map, MKLocalSearchCompleter, MKGeocodingRequest) | Intégré, pas de clé API |
| Géocodage | MKGeocodingRequest / MKReverseGeocodingRequest | Remplace CLGeocoder déprécié |
| Persistance | UserDefaults + JSON | Suffisant pour 20 entrées d'historique |
| Calendrier | ICSGenerator maison | RFC 5545 compliant, pas de lib externe |
| Distribution | `.dmg` non signé | GitHub Releases, pas d'App Store |
