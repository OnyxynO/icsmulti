import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Vue principale de l'application
struct ContentView: View {
    @State private var store = EvenementStore()
    @State private var messageErreur: String = ""
    @State private var afficherErreur = false
    @State private var exportReussi = false
    @State private var afficherHistorique = false
    @State private var tacheDisparition: Task<Void, Never>?
    @FocusState private var champActif: ChampPrincipal?

    /// Champs navigables par Tab/Return dans l'interface
    enum ChampPrincipal: Hashable {
        case titre, notes, boutonAjouter
        case lieu(UUID)
    }

    private var peutExporter: Bool {
        !store.titre.trimmingCharacters(in: .whitespaces).isEmpty && !store.occurrences.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            FormMetadonnees(store: store, champActif: $champActif)
                .padding()

            Divider()

            ListeOccurrences(store: store, champActif: $champActif)

            Divider()

            HStack {
                Spacer()
                Button("Exporter .ics") {
                    exporter()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!peutExporter)
                .keyboardShortcut("s", modifiers: .command)
                .padding()
            }
        }
        .frame(minWidth: 700, minHeight: 400)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                champActif = .titre
            }
        }
        .alert("Erreur de validation", isPresented: $afficherErreur) {
            Button("OK") {}
        } message: {
            Text(messageErreur)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    afficherHistorique = true
                } label: {
                    Label("Historique", systemImage: "clock.arrow.circlepath")
                }
                .help("Historique des exports")
            }
        }
        .sheet(isPresented: $afficherHistorique) {
            HistoriqueSheet { evenement in
                chargerEvenement(evenement)
            }
        }
        .overlay(alignment: .bottom) {
            if exportReussi {
                Text("Fichier exporté avec succès")
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.green.opacity(0.85), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: exportReussi)
    }

    @MainActor
    private func exporter() {
        for occurrence in store.occurrences {
            guard occurrence.dateFin >= occurrence.dateDebut else {
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
            HistoriqueService.sauvegarder(store)
            // Feedback visuel
            exportReussi = true
            tacheDisparition?.cancel()
            tacheDisparition = Task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    exportReussi = false
                }
            }
        } catch {
            messageErreur = "Impossible d'écrire le fichier : \(error.localizedDescription)"
            afficherErreur = true
        }
    }

    private func chargerEvenement(_ evenement: EvenementSauvegarde) {
        store.titre = evenement.titre
        store.notes = evenement.notes
        store.occurrences = evenement.occurrences
    }
}

#Preview {
    ContentView()
}
