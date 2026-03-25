import Foundation
import Observation

// Etat global de l'application — titre, description, liste des occurrences
@Observable
class EvenementStore {
    var titre: String = ""
    var description: String = ""
    var occurrences: [ICSOccurrence] = []
}
