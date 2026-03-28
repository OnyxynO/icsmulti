import Foundation
import Observation

// Etat global de l'application — titre, notes, liste des occurrences
@Observable
class EvenementStore {
    var titre: String = ""
    var notes: String = ""
    var occurrences: [ICSOccurrence] = []

    /// Trie les occurrences par date de début croissante
    func trierOccurrences() {
        occurrences.sort { $0.dateDebut < $1.dateDebut }
    }
}
