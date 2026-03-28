import SwiftUI

/// Liste des occurrences avec bouton d'ajout
struct ListeOccurrences: View {
    @Bindable var store: EvenementStore
    @FocusState.Binding var champActif: ContentView.ChampPrincipal?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // En-tête avec compteur et bouton ajouter (toujours au même endroit)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Occurrences")
                    .font(.headline)
                if !store.occurrences.isEmpty {
                    Text("\(store.occurrences.count) occurrence\(store.occurrences.count > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    ajouterOccurrence()
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .focusable()
                .focused($champActif, equals: .boutonAjouter)
                .onKeyPress(.space) { ajouterOccurrence(); return .handled }
                .onKeyPress(.return) { ajouterOccurrence(); return .handled }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            if store.occurrences.isEmpty {
                // État vide
                ContentUnavailableView(
                    "Aucune occurrence",
                    systemImage: "calendar.badge.plus",
                    description: Text("Cliquez sur + pour ajouter une date")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.occurrences) { occurrence in
                            LigneOccurrence(
                                occurrence: Binding(
                                    get: {
                                        store.occurrences.first(where: { $0.id == occurrence.id }) ?? occurrence
                                    },
                                    set: { nouvelleValeur in
                                        guard let index = store.occurrences.firstIndex(where: { $0.id == occurrence.id }) else { return }
                                        store.occurrences[index] = nouvelleValeur
                                    }
                                ),
                                champActif: $champActif,
                                onDupliquer: {
                                    dupliquerOccurrence(occurrence)
                                }
                            ) {
                                store.occurrences.removeAll { $0.id == occurrence.id }
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
        }
    }

    private func ajouterOccurrence() {
        let calendrier = Calendar.current
        var composants = calendrier.dateComponents([.year, .month, .day], from: Date())
        composants.hour = 9
        composants.minute = 0
        composants.second = 0
        composants.timeZone = TimeZone(identifier: "Europe/Paris")
        let debut = calendrier.date(from: composants) ?? Date()
        let fin = calendrier.date(byAdding: .hour, value: 1, to: debut) ?? debut
        let nouvelle = ICSOccurrence(dateDebut: debut, dateFin: fin)
        store.occurrences.append(nouvelle)
        store.trierOccurrences()
        // Focus sur le champ Lieu de la nouvelle occurrence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            champActif = .lieu(nouvelle.id)
        }
    }

    private func dupliquerOccurrence(_ originale: ICSOccurrence) {
        let calendrier = Calendar.current
        guard let nouveauDebut = calendrier.date(byAdding: .day, value: 7, to: originale.dateDebut),
              let nouvelleFin = calendrier.date(byAdding: .day, value: 7, to: originale.dateFin) else { return }

        let copie = ICSOccurrence(
            dateDebut: nouveauDebut,
            dateFin: nouvelleFin,
            lieu: originale.lieu,
            touteLaJournee: originale.touteLaJournee,
            rappelMinutes: originale.rappelMinutes
        )
        store.occurrences.append(copie)
        store.trierOccurrences()
    }
}
