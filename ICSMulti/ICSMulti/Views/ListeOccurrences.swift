import SwiftUI

/// Liste des occurrences avec bouton d'ajout
struct ListeOccurrences: View {
    @Bindable var store: EvenementStore
    @FocusState.Binding var champActif: ContentView.ChampPrincipal?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Occurrences")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 10)

            if store.occurrences.isEmpty {
                Text("Aucune occurrence — cliquez sur Ajouter")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                Divider()
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
                                champActif: $champActif
                            ) {
                                store.occurrences.removeAll { $0.id == occurrence.id }
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 240)
            }

            Button {
                ajouterOccurrence()
            } label: {
                Label("Ajouter une occurrence", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .focusable()
            .focused($champActif, equals: .boutonAjouter)
            .onKeyPress(.space) { ajouterOccurrence(); return .handled }
            .onKeyPress(.return) { ajouterOccurrence(); return .handled }
            .padding(.horizontal)
            .padding(.vertical, 10)
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
        // Focus sur le champ Lieu de la nouvelle occurrence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            champActif = .lieu(nouvelle.id)
        }
    }
}
