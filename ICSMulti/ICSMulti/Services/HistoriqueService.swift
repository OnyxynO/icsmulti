import Foundation

/// Représentation d'un événement sauvegardé dans l'historique
struct EvenementSauvegarde: Identifiable, Codable {
    let id: UUID
    let dateSauvegarde: Date
    let nbOccurrences: Int
    let occurrences: [ICSOccurrence]  // titre/notes désormais dans chaque ICSOccurrence

    init(depuis store: EvenementStore) {
        self.id = UUID()
        self.dateSauvegarde = Date()
        self.nbOccurrences = store.occurrences.count
        self.occurrences = store.occurrences
    }
}

/// Gestion de l'historique des événements exportés (max 20, UserDefaults)
struct HistoriqueService {
    private static let cleUserDefaults = "historiqueEvenements_v2"
    private static let maxEntrees = 20

    /// Sauvegarde l'état actuel du store dans l'historique
    static func sauvegarder(_ store: EvenementStore) {
        var historique = charger()
        let entree = EvenementSauvegarde(depuis: store)
        historique.insert(entree, at: 0)
        if historique.count > maxEntrees {
            historique = Array(historique.prefix(maxEntrees))
        }
        if let donnees = try? JSONEncoder().encode(historique) {
            UserDefaults.standard.set(donnees, forKey: cleUserDefaults)
        }
    }

    /// Charge l'historique depuis UserDefaults
    static func charger() -> [EvenementSauvegarde] {
        guard let donnees = UserDefaults.standard.data(forKey: cleUserDefaults),
              let historique = try? JSONDecoder().decode([EvenementSauvegarde].self, from: donnees) else {
            return []
        }
        return historique
    }

    /// Supprime tout l'historique
    static func toutSupprimer() {
        UserDefaults.standard.removeObject(forKey: cleUserDefaults)
    }

    /// Supprime une entrée de l'historique par ID
    static func supprimer(id: UUID) {
        var historique = charger()
        historique.removeAll { $0.id == id }
        if let donnees = try? JSONEncoder().encode(historique) {
            UserDefaults.standard.set(donnees, forKey: cleUserDefaults)
        }
    }
}
