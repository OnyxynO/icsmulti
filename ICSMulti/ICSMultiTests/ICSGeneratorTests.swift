import Testing
import Foundation
@testable import ICSMulti

/// Tests unitaires pour ICSGenerator — génération de fichiers .ics conformes RFC 5545
struct ICSGeneratorTests {

    // MARK: - Structure globale

    @Test func structureCalendrierValide() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("BEGIN:VCALENDAR"))
        #expect(resultat.contains("VERSION:2.0"))
        #expect(resultat.contains("PRODID:-//ICSMulti//FR"))
        #expect(resultat.contains("CALSCALE:GREGORIAN"))
        #expect(resultat.contains("END:VCALENDAR"))
    }

    @Test func terminaisonsLignesCRLF() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test")]

        let resultat = ICSGenerator.generer(depuis: store)

        // Chaque ligne doit se terminer par \r\n (CRLF)
        let lignes = resultat.components(separatedBy: "\r\n")
        // La dernière entrée après le split final est vide
        #expect(lignes.last == "")
        // Vérifier qu'il n'y a pas de \n isolé (sans \r précédent)
        let sansRetourChariot = resultat.replacingOccurrences(of: "\r\n", with: "")
        #expect(!sansRetourChariot.contains("\n") || sansRetourChariot.contains("\\n"))
    }

    // MARK: - VEVENT

    @Test func veventContientDTSTAMP() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("DTSTAMP;TZID=Europe/Paris:"))
    }

    @Test func veventContientUID() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("@icsmulti"))
    }

    @Test func multiOccurrencesGenereMultiVEVENT() {
        let store = EvenementStore()
        store.occurrences = [
            creerOccurrence(titre: "Premier"),
            creerOccurrence(titre: "Deuxième"),
            creerOccurrence(titre: "Troisième")
        ]

        let resultat = ICSGenerator.generer(depuis: store)

        let nbBegin = resultat.components(separatedBy: "BEGIN:VEVENT").count - 1
        let nbEnd = resultat.components(separatedBy: "END:VEVENT").count - 1
        #expect(nbBegin == 3)
        #expect(nbEnd == 3)
    }

    // MARK: - Événement avec heure

    @Test func evenementAvecHeureUtiliseTZID() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Réunion", touteLaJournee: false)]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("DTSTART;TZID=Europe/Paris:"))
        #expect(resultat.contains("DTEND;TZID=Europe/Paris:"))
    }

    // MARK: - Événement journée entière

    @Test func journeeEntiereUtiliseVALUEDATE() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Congé", touteLaJournee: true)]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("DTSTART;VALUE=DATE:"))
        #expect(resultat.contains("DTEND;VALUE=DATE:"))
        // Ne doit PAS contenir de 'T' dans les dates VALUE=DATE
        let lignes = resultat.components(separatedBy: "\r\n")
        for ligne in lignes {
            if ligne.hasPrefix("DTSTART;VALUE=DATE:") {
                let valeur = String(ligne.dropFirst("DTSTART;VALUE=DATE:".count))
                #expect(!valeur.contains("T"), "La date VALUE=DATE ne doit pas contenir 'T'")
            }
        }
    }

    @Test func journeeEntiereFinEstJPlusUn() {
        // RFC 5545 : DTEND exclusif → une journée du 15 au 15 doit avoir DTEND = 16
        let calendrier = Calendar.current
        let debut = calendrier.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let fin = debut // même jour

        let store = EvenementStore()
        store.occurrences = [
            ICSOccurrence(titre: "Jour unique", dateDebut: debut, dateFin: fin, touteLaJournee: true)
        ]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("DTSTART;VALUE=DATE:20260615"))
        #expect(resultat.contains("DTEND;VALUE=DATE:20260616"))
    }

    // MARK: - Échappement RFC 5545

    @Test func echappementVirgule() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Salle A, Salle B")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("SUMMARY:Salle A\\, Salle B"))
    }

    @Test func echappementPointVirgule() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test; suite")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("SUMMARY:Test\\; suite"))
    }

    @Test func echappementAntislash() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Chemin\\dossier")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("SUMMARY:Chemin\\\\dossier"))
    }

    @Test func echappementSautDeLigne() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Ligne1\nLigne2")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("SUMMARY:Ligne1\\nLigne2"))
    }

    @Test func echappementDescription() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", notes: "Note avec, virgule; et point-virgule")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("DESCRIPTION:Note avec\\, virgule\\; et point-virgule"))
    }

    @Test func echappementLieu() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", lieu: "12, rue de la Paix; Paris")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("LOCATION:12\\, rue de la Paix\\; Paris"))
    }

    // MARK: - Line folding

    @Test func lineFoldingLignesLongues() {
        // Un titre de plus de 75 octets doit être replié
        let titreLong = String(repeating: "A", count: 80)
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: titreLong)]

        let resultat = ICSGenerator.generer(depuis: store)

        // Vérifier que la ligne SUMMARY a été repliée (contient CRLF + espace)
        let lignesBrutes = resultat.components(separatedBy: "\r\n")
        let ligneContinuation = lignesBrutes.first { $0.hasPrefix(" ") && $0.contains("AAA") }
        #expect(ligneContinuation != nil, "Les lignes longues doivent être repliées avec continuation")
    }

    @Test func lineFoldingLignesCourtesPasRepliees() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Court")]

        let resultat = ICSGenerator.generer(depuis: store)

        // La ligne SUMMARY ne doit pas être repliée
        let lignes = resultat.components(separatedBy: "\r\n")
        let indiceSummary = lignes.firstIndex { $0.contains("SUMMARY:Court") }
        #expect(indiceSummary != nil)
        if let idx = indiceSummary, idx + 1 < lignes.count {
            // La ligne suivante ne doit pas être une continuation
            #expect(!lignes[idx + 1].hasPrefix(" ") || lignes[idx + 1].hasPrefix("DESCRIPTION") || lignes[idx + 1].hasPrefix("LOCATION") || lignes[idx + 1].hasPrefix("BEGIN") || lignes[idx + 1].hasPrefix("END"))
        }
    }

    // MARK: - VALARM (rappels)

    @Test func rappelMinutesGenereVALARM() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Rendez-vous", rappelMinutes: 30)]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("BEGIN:VALARM"))
        #expect(resultat.contains("TRIGGER:-PT30M"))
        #expect(resultat.contains("ACTION:DISPLAY"))
        #expect(resultat.contains("END:VALARM"))
    }

    @Test func rappelHeuresGenereVALARM() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", rappelMinutes: 120)]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("TRIGGER:-PT2H"))
    }

    @Test func rappelJourGenereVALARM() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", rappelMinutes: 1440)]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("TRIGGER:-P1D"))
    }

    @Test func pasDeRappelPasDeVALARM() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", rappelMinutes: nil)]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(!resultat.contains("BEGIN:VALARM"))
        #expect(!resultat.contains("TRIGGER:"))
    }

    // MARK: - Champs optionnels

    @Test func notesVidesOmettentDESCRIPTION() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", notes: "")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(!resultat.contains("DESCRIPTION:"))
    }

    @Test func lieuVideOmetLOCATION() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", lieu: "")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(!resultat.contains("LOCATION:"))
    }

    @Test func notesPresentes() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", notes: "Notes importantes")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("DESCRIPTION:Notes importantes"))
    }

    @Test func lieuPresent() {
        let store = EvenementStore()
        store.occurrences = [creerOccurrence(titre: "Test", lieu: "Paris")]

        let resultat = ICSGenerator.generer(depuis: store)

        #expect(resultat.contains("LOCATION:Paris"))
    }

    // MARK: - Helpers

    /// Crée une occurrence de test avec des valeurs par défaut
    private func creerOccurrence(
        titre: String = "Test",
        notes: String = "",
        lieu: String = "",
        touteLaJournee: Bool = false,
        rappelMinutes: Int? = nil
    ) -> ICSOccurrence {
        let maintenant = Date()
        let dansTroisHeures = maintenant.addingTimeInterval(3 * 3600)
        return ICSOccurrence(
            titre: titre,
            notes: notes,
            dateDebut: maintenant,
            dateFin: dansTroisHeures,
            lieu: lieu,
            touteLaJournee: touteLaJournee,
            rappelMinutes: rappelMinutes
        )
    }
}
