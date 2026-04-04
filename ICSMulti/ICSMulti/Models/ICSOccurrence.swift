import Foundation

// Une occurrence = un événement indépendant avec titre, notes, dates, lieu, rappel
struct ICSOccurrence: Identifiable, Codable {
    let id: UUID
    var titre: String
    var notes: String
    var dateDebut: Date
    var dateFin: Date
    var lieu: String
    var touteLaJournee: Bool
    var rappelMinutes: Int?

    init(id: UUID = UUID(), titre: String = "", notes: String = "",
         dateDebut: Date, dateFin: Date,
         lieu: String = "", touteLaJournee: Bool = false, rappelMinutes: Int? = nil) {
        self.id = id
        self.titre = titre
        self.notes = notes
        self.dateDebut = dateDebut
        self.dateFin = dateFin
        self.lieu = lieu
        self.touteLaJournee = touteLaJournee
        self.rappelMinutes = rappelMinutes
    }
}
