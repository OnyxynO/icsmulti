import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Vue principale

struct ContentView: View {
    @State private var store = EvenementStore()
    @State private var messageErreur: String = ""
    @State private var afficherErreur = false

    private var peutExporter: Bool {
        !store.titre.trimmingCharacters(in: .whitespaces).isEmpty && !store.occurrences.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            FormMetadonnees(store: store)
                .padding()

            Divider()

            ListeOccurrences(store: store)

            Divider()

            HStack {
                Spacer()
                Button("Exporter .ics") {
                    exporter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!peutExporter)
                .padding()
            }
        }
        .frame(minWidth: 560, minHeight: 400)
        .alert("Erreur de validation", isPresented: $afficherErreur) {
            Button("OK") {}
        } message: {
            Text(messageErreur)
        }
    }

    private func exporter() {
        for occurrence in store.occurrences {
            guard occurrence.dateFin > occurrence.dateDebut else {
                messageErreur = "L'heure de fin doit être postérieure à l'heure de début pour chaque occurrence."
                afficherErreur = true
                return
            }
        }

        let contenu = ICSGenerator.generer(depuis: store)
        let nomFichier = store.titre.trimmingCharacters(in: .whitespaces)

        let panneau = NSSavePanel()
        if let icsType = UTType(filenameExtension: "ics") {
            panneau.allowedContentTypes = [icsType]
        }
        panneau.nameFieldStringValue = "\(nomFichier).ics"
        panneau.canCreateDirectories = true
        panneau.title = "Enregistrer le calendrier"

        guard panneau.runModal() == .OK, let url = panneau.url else { return }

        do {
            try contenu.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            messageErreur = "Impossible d'écrire le fichier : \(error.localizedDescription)"
            afficherErreur = true
        }
    }
}

// MARK: - Formulaire métadonnées

struct FormMetadonnees: View {
    @Bindable var store: EvenementStore

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                Text("Titre")
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.trailing)
                TextField("Nom de l'événement", text: $store.titre)
                    .textFieldStyle(.roundedBorder)
            }
            GridRow {
                Text("Description")
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.trailing)
                TextField("Optionnelle", text: $store.description)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

// MARK: - Liste des occurrences

struct ListeOccurrences: View {
    @Bindable var store: EvenementStore

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
                        ForEach($store.occurrences) { $occurrence in
                            LigneOccurrence(occurrence: $occurrence) {
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
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private func ajouterOccurrence() {
        let calendrier = Calendar.current
        var comp = calendrier.dateComponents([.year, .month, .day], from: Date())
        comp.hour = 9
        comp.minute = 0
        comp.second = 0
        comp.timeZone = TimeZone(identifier: "Europe/Paris")
        let debut = calendrier.date(from: comp) ?? Date()
        let fin = calendrier.date(byAdding: .hour, value: 1, to: debut) ?? debut
        store.occurrences.append(ICSOccurrence(dateDebut: debut, dateFin: fin))
    }
}

// MARK: - Ligne d'occurrence

struct LigneOccurrence: View {
    @Binding var occurrence: ICSOccurrence
    let onSupprimer: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            DatePicker("", selection: $occurrence.dateDebut, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .frame(minWidth: 200)

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
                .font(.caption)

            DatePicker("", selection: $occurrence.dateFin, displayedComponents: .hourAndMinute)
                .labelsHidden()

            TextField("Lieu", text: $occurrence.lieu)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 80, maxWidth: 160)

            Button(action: onSupprimer) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
