import SwiftUI
import MapKit

/// Ligne individuelle d'une occurrence (date, heure, lieu, suppression)
struct LigneOccurrence: View {
    @Binding var occurrence: ICSOccurrence
    @FocusState.Binding var champActif: ContentView.ChampPrincipal?
    let onSupprimer: () -> Void

    @State private var serviceAdresse = RechercheAdresseService()
    @State private var afficherSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Toggle("", isOn: $occurrence.touteLaJournee)
                    .toggleStyle(.checkbox)
                    .help("Journée entière")

                if occurrence.touteLaJournee {
                    DatePicker("", selection: $occurrence.dateDebut, displayedComponents: .date)
                        .labelsHidden()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    DatePicker("", selection: $occurrence.dateFin, displayedComponents: .date)
                        .labelsHidden()
                } else {
                    DatePicker("", selection: $occurrence.dateDebut, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(minWidth: 200)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    DatePicker("", selection: $occurrence.dateFin, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .frame(minWidth: 200)
                }

                TextField("Lieu", text: $occurrence.lieu)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 80, maxWidth: 160)
                    .focused($champActif, equals: .lieu(occurrence.id))
                    .onChange(of: occurrence.lieu) { _, nouveauLieu in
                        serviceAdresse.recherche = nouveauLieu
                        afficherSuggestions = nouveauLieu.count >= 3
                    }

                // Bouton ouvrir dans Apple Plans
                if !occurrence.lieu.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        RechercheAdresseService.ouvrirDansPlans(adresse: occurrence.lieu)
                    } label: {
                        Image(systemName: "map")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Ouvrir dans Plans")
                }

                Button(action: onSupprimer) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Liste de suggestions d'adresses
            if afficherSuggestions && !serviceAdresse.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(serviceAdresse.suggestions.prefix(5), id: \.self) { suggestion in
                        Button {
                            occurrence.lieu = [suggestion.title, suggestion.subtitle]
                                .filter { !$0.isEmpty }
                                .joined(separator: ", ")
                            afficherSuggestions = false
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .font(.callout)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator))
                .padding(.leading, 200)
                .padding(.trailing, 60)
                .padding(.bottom, 4)
            }
        }
    }
}
