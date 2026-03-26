import Foundation

// Une occurrence de l'événement : dates, lieu
struct ICSOccurrence: Identifiable {
    let id: UUID = UUID()
    var dateDebut: Date
    var dateFin: Date
    var lieu: String = ""
    var touteLaJournee: Bool = false
}
