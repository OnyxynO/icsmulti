import SwiftUI

/// Feuille affichant l'historique des événements exportés
struct HistoriqueSheet: View {
    let onCharger: (EvenementSauvegarde) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var historique: [EvenementSauvegarde] = []

    /// Formateur de date pour l'affichage
    private static let formateurDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "fr_FR")
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack {
                Text("Historique des exports")
                    .font(.headline)
                Spacer()
                if !historique.isEmpty {
                    Button("Tout supprimer", role: .destructive) {
                        HistoriqueService.toutSupprimer()
                        historique.removeAll()
                    }
                    .foregroundStyle(.red)
                }
                Button("Fermer") { dismiss() }
            }
            .padding()

            Divider()

            if historique.isEmpty {
                ContentUnavailableView(
                    "Aucun historique",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Les événements exportés apparaîtront ici")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(historique) { entree in
                        HStack {
                            Button {
                                onCharger(entree)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entree.occurrences.first?.titre ?? "Sans titre")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    HStack(spacing: 8) {
                                        Text(Self.formateurDate.string(from: entree.dateSauvegarde))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\u{2022}")
                                            .foregroundStyle(.tertiary)
                                        Text("\(entree.nbOccurrences) événement\(entree.nbOccurrences > 1 ? "s" : "")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                HistoriqueService.supprimer(id: entree.id)
                                historique.removeAll { $0.id == entree.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .help("Supprimer de l'historique")
                        }
                    }
                }
            }
        }
        .frame(minWidth: 400, idealWidth: 480, minHeight: 300, idealHeight: 400)
        .onAppear {
            historique = HistoriqueService.charger()
        }
    }
}
