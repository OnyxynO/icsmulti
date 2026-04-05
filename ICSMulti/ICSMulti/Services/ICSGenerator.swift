import Foundation

// Génère un fichier .ics (RFC 5545) depuis un EvenementStore
struct ICSGenerator {

    // Formateur date+heure ICS : yyyyMMdd'T'HHmmss, fuseau Europe/Paris
    private static let formateurDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd'T'HHmmss"
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        return f
    }()

    // Formateur date seule ICS : yyyyMMdd (pour les événements journée entière)
    private static let formateurDateSeule: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        return f
    }()

    // Échappe une valeur texte selon RFC 5545 §3.3.11
    // Ordre important : \ en premier pour ne pas double-échapper
    private static func echapper(_ valeur: String) -> String {
        valeur
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";",  with: "\\;")
            .replacingOccurrences(of: ",",  with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }

    // Replie les lignes longues selon RFC 5545 §3.1 (max 75 octets, continuation avec CRLF + espace)
    private static func replierLigne(_ ligne: String) -> String {
        let octets = Array(ligne.utf8)
        guard octets.count > 75 else { return ligne }
        var resultat: [UInt8] = []
        var debut = 0
        while debut < octets.count {
            let fin = min(debut + 75, octets.count)
            resultat.append(contentsOf: octets[debut..<fin])
            if fin < octets.count {
                // CRLF + espace = continuation RFC 5545
                resultat.append(contentsOf: [0x0D, 0x0A, 0x20])
            }
            debut = fin
        }
        return String(bytes: resultat, encoding: .utf8) ?? ligne
    }

    /// Formate la durée de rappel en format RFC 5545 (ISO 8601 duration)
    private static func formaterDureeRappel(_ minutes: Int) -> String {
        if minutes == 1440 {
            return "-P1D"
        } else if minutes >= 60 && minutes % 60 == 0 {
            return "-PT\(minutes / 60)H"
        } else {
            return "-PT\(minutes)M"
        }
    }

    // Retourne le contenu complet du fichier .ics
    static func generer(depuis store: EvenementStore) -> String {
        var lignes: [String] = []

        lignes.append("BEGIN:VCALENDAR")
        lignes.append("VERSION:2.0")
        lignes.append("PRODID:-//ICSMulti//FR")
        lignes.append("CALSCALE:GREGORIAN")

        let horodatage = formateurDate.string(from: Date())

        for occurrence in store.occurrences {
            lignes.append("BEGIN:VEVENT")
            lignes.append("UID:\(UUID().uuidString)@icsmulti")
            lignes.append("DTSTAMP;TZID=Europe/Paris:\(horodatage)")
            if occurrence.touteLaJournee {
                // RFC 5545 : VALUE=DATE, fin exclusive (J+1)
                let finExclusive = Calendar.current.date(byAdding: .day, value: 1, to: occurrence.dateFin) ?? occurrence.dateFin
                lignes.append("DTSTART;VALUE=DATE:\(formateurDateSeule.string(from: occurrence.dateDebut))")
                lignes.append("DTEND;VALUE=DATE:\(formateurDateSeule.string(from: finExclusive))")
            } else {
                lignes.append("DTSTART;TZID=Europe/Paris:\(formateurDate.string(from: occurrence.dateDebut))")
                lignes.append("DTEND;TZID=Europe/Paris:\(formateurDate.string(from: occurrence.dateFin))")
            }
            lignes.append("SUMMARY:\(echapper(occurrence.titre))")
            if !occurrence.notes.isEmpty {
                lignes.append("DESCRIPTION:\(echapper(occurrence.notes))")
            }
            if !occurrence.lieu.isEmpty {
                lignes.append("LOCATION:\(echapper(occurrence.lieu))")
            }
            // VALARM — rappel optionnel
            if let rappel = occurrence.rappelMinutes {
                lignes.append("BEGIN:VALARM")
                lignes.append("TRIGGER:\(formaterDureeRappel(rappel))")
                lignes.append("ACTION:DISPLAY")
                lignes.append("DESCRIPTION:Rappel")
                lignes.append("END:VALARM")
            }
            lignes.append("END:VEVENT")
        }

        lignes.append("END:VCALENDAR")

        // RFC 5545 : fins de ligne CRLF + repli des lignes longues (>75 octets)
        return lignes.map { replierLigne($0) }.joined(separator: "\r\n") + "\r\n"
    }
}
