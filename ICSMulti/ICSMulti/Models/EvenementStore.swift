import Foundation
import Observation

// Etat global de l'application — titre, notes, liste des occurrences
@Observable
class EvenementStore {
    var titre: String = ""
    var notes: String = ""
    var occurrences: [ICSOccurrence] = []
}
