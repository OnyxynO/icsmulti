import Foundation

// Génère un fichier .ics (RFC 5545) depuis un EvenementStore
struct ICSGenerator {

    // Formateur de date au format ICS : yyyyMMdd'T'HHmmss, fuseau Europe/Paris
    private static let formateurDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss"
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        return f
    }()

    // Retourne le contenu complet du fichier .ics
    static func generer(depuis store: EvenementStore) -> String {
        var lignes: [String] = []

        lignes.append("BEGIN:VCALENDAR")
        lignes.append("VERSION:2.0")
        lignes.append("PRODID:-//ICSMulti//FR")
        lignes.append("CALSCALE:GREGORIAN")

        for occurrence in store.occurrences {
            lignes.append("BEGIN:VEVENT")
            lignes.append("UID:\(UUID().uuidString)@icsmulti")
            lignes.append("DTSTART;TZID=Europe/Paris:\(formateurDate.string(from: occurrence.dateDebut))")
            lignes.append("DTEND;TZID=Europe/Paris:\(formateurDate.string(from: occurrence.dateFin))")
            lignes.append("SUMMARY:\(store.titre)")
            if !store.description.isEmpty {
                lignes.append("DESCRIPTION:\(store.description)")
            }
            if !occurrence.lieu.isEmpty {
                lignes.append("LOCATION:\(occurrence.lieu)")
            }
            lignes.append("END:VEVENT")
        }

        lignes.append("END:VCALENDAR")

        // RFC 5545 impose des fins de ligne CRLF
        return lignes.joined(separator: "\r\n") + "\r\n"
    }
}
