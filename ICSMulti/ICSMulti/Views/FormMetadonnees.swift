import SwiftUI

/// Formulaire de saisie du titre et des notes de l'événement
struct FormMetadonnees: View {
    @Bindable var store: EvenementStore
    @FocusState.Binding var champActif: ContentView.ChampPrincipal?

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                Text("Titre")
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.trailing)
                TextField("Nom de l'événement", text: $store.titre)
                    .textFieldStyle(.roundedBorder)
                    .focused($champActif, equals: .titre)
                    .onSubmit { champActif = .notes }
            }
            GridRow {
                Text("Notes")
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.trailing)
                TextField("Optionnelle", text: $store.notes)
                    .textFieldStyle(.roundedBorder)
                    .focused($champActif, equals: .notes)
                    .onSubmit { champActif = .boutonAjouter }
                    .onKeyPress(.tab) { champActif = .boutonAjouter; return .handled }
            }
        }
        // Focus initial géré par .defaultFocus dans ContentView
    }
}
