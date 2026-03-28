import Foundation

// Une occurrence de l'événement : dates, lieu, rappel
struct ICSOccurrence: Identifiable, Codable {
    let id: UUID
    var dateDebut: Date
    var dateFin: Date
    var lieu: String
    var touteLaJournee: Bool
    var rappelMinutes: Int?

    // Initialisation par défaut (conserve la compatibilité avec les call sites existants)
    init(id: UUID = UUID(), dateDebut: Date, dateFin: Date, lieu: String = "", touteLaJournee: Bool = false, rappelMinutes: Int? = nil) {
        self.id = id
        self.dateDebut = dateDebut
        self.dateFin = dateFin
        self.lieu = lieu
        self.touteLaJournee = touteLaJournee
        self.rappelMinutes = rappelMinutes
    }
}
