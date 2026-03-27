import SwiftUI

/// Ligne individuelle d'une occurrence (date, heure, lieu, suppression)
struct LigneOccurrence: View {
    @Binding var occurrence: ICSOccurrence
    @FocusState.Binding var champActif: ContentView.ChampPrincipal?
    let onSupprimer: () -> Void

    var body: some View {
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
