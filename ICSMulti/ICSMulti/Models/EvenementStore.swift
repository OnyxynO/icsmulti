import Foundation
import Observation

// Etat global de l'application — liste des occurrences (titre/notes dans chaque occurrence)
@Observable
class EvenementStore {
    var occurrences: [ICSOccurrence] = []

    /// Trie les occurrences par date de début croissante
    func trierOccurrences() {
        occurrences.sort { $0.dateDebut < $1.dateDebut }
    }
}
