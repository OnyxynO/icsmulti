import SwiftUI
import MapKit

/// Ligne individuelle d'une occurrence (date, heure, lieu, rappel, duplication, suppression)
struct LigneOccurrence: View {
    @Binding var occurrence: ICSOccurrence
    @FocusState.Binding var champActif: ContentView.ChampPrincipal?
    let onDupliquer: () -> Void
    let onSupprimer: () -> Void

    @State private var serviceAdresse = RechercheAdresseService()
    @State private var afficherSuggestions = false
    @State private var afficherMapPicker = false
    @State private var selectionEnCours = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Toggle("Journée", isOn: $occurrence.touteLaJournee)
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
                        if selectionEnCours {
                            selectionEnCours = false
                            return
                        }
                        serviceAdresse.recherche = nouveauLieu
                        afficherSuggestions = nouveauLieu.count >= 3
                    }

                // Bouton choisir sur la carte
                Button {
                    afficherMapPicker = true
                } label: {
                    Image(systemName: "map")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Choisir sur la carte")

                // Menu rappel compact
                Menu {
                    Button("Aucun") { occurrence.rappelMinutes = nil }
                    Divider()
                    Button("15 minutes avant") { occurrence.rappelMinutes = 15 }
                    Button("30 minutes avant") { occurrence.rappelMinutes = 30 }
                    Button("1 heure avant") { occurrence.rappelMinutes = 60 }
                    Button("2 heures avant") { occurrence.rappelMinutes = 120 }
                    Button("1 jour avant") { occurrence.rappelMinutes = 1440 }
                } label: {
                    Image(systemName: occurrence.rappelMinutes != nil ? "bell.fill" : "bell")
                        .foregroundStyle(occurrence.rappelMinutes != nil ? .blue : .secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 30)
                .help(libelleRappel(occurrence.rappelMinutes))

                // Bouton dupliquer
                Button(action: onDupliquer) {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Dupliquer (+7 jours)")

                // Bouton supprimer
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
                            let adresse = [suggestion.title, suggestion.subtitle]
                                .filter { !$0.isEmpty }
                                .joined(separator: ", ")
                            selectionEnCours = true
                            occurrence.lieu = adresse
                            RechercheAdresseService.sauvegarderLieu(adresse)
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
        .sheet(isPresented: $afficherMapPicker, onDismiss: {
            selectionEnCours = true
        }) {
            MapPickerSheet(adresseSelectionnee: $occurrence.lieu)
        }
    }

    /// Libellé descriptif du rappel pour l'aide contextuelle
    private func libelleRappel(_ minutes: Int?) -> String {
        switch minutes {
        case nil: return "Aucun rappel"
        case 15: return "Rappel 15 min avant"
        case 30: return "Rappel 30 min avant"
        case 60: return "Rappel 1h avant"
        case 120: return "Rappel 2h avant"
        case 1440: return "Rappel 1 jour avant"
        default: return "Rappel \(minutes!) min avant"
        }
    }
}
