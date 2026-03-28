import SwiftUI
import MapKit

/// Fenêtre de sélection d'adresse : recherche textuelle + clic sur carte
struct MapPickerSheet: View {
    @Binding var adresseSelectionnee: String
    @Environment(\.dismiss) var dismiss

    @State private var texteRecherche: String = ""
    @State private var completer = RechercheAdresseService()
    @State private var afficherSuggestions = false

    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
        )
    )
    @State private var coordonneePin: CLLocationCoordinate2D?
    @State private var adresseConfirmee: String = ""
    @State private var enGeocoding = false

    @State private var requeteReverseGeocoding: MKReverseGeocodingRequest?

    var body: some View {
        VStack(spacing: 0) {
            barreRecherche
            Divider()
            carte
            Divider()
            barreConfirmation
        }
        .frame(minWidth: 540, idealWidth: 620, minHeight: 500, idealHeight: 560)
        .onAppear {
            if !adresseSelectionnee.isEmpty {
                texteRecherche = adresseSelectionnee
                adresseConfirmee = adresseSelectionnee
                centrerSurAdresse(adresseSelectionnee)
            }
        }
    }

    // MARK: - Barre de recherche

    private var barreRecherche: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Rechercher une adresse, une ville...", text: $texteRecherche)
                    .textFieldStyle(.plain)
                    .onChange(of: texteRecherche) { _, val in
                        completer.recherche = val
                        afficherSuggestions = val.count >= 2
                    }
                if !texteRecherche.isEmpty {
                    Button {
                        texteRecherche = ""
                        afficherSuggestions = false
                        completer.recherche = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if afficherSuggestions && !completer.suggestions.isEmpty {
                Divider()
                VStack(spacing: 0) {
                    ForEach(completer.suggestions.prefix(6), id: \.self) { s in
                        Button {
                            selectionnerSuggestion(s)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "mappin")
                                    .foregroundStyle(.red)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title)
                                        .font(.callout)
                                    if !s.subtitle.isEmpty {
                                        Text(s.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .background(.background)
            }
        }
        .background(.background)
    }

    // MARK: - Carte

    private var carte: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let coord = coordonneePin {
                    Marker(adresseConfirmee, coordinate: coord)
                        .tint(.red)
                }
            }
            .onTapGesture { point in
                guard let coord = proxy.convert(point, from: .local) else { return }
                afficherSuggestions = false
                coordonneePin = coord
                geocoderCoordonnee(coord)
            }
        }
        .frame(minHeight: 300)
    }

    // MARK: - Barre de confirmation

    private var barreConfirmation: some View {
        HStack(spacing: 12) {
            if enGeocoding {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: adresseConfirmee.isEmpty ? "hand.tap" : "checkmark.circle.fill")
                    .foregroundStyle(adresseConfirmee.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.green))
                    .frame(width: 16, height: 16)
            }

            Text(adresseConfirmee.isEmpty
                 ? "Recherchez ou cliquez sur la carte"
                 : adresseConfirmee)
                .foregroundStyle(adresseConfirmee.isEmpty ? .secondary : .primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Annuler") { dismiss() }

            Button("Choisir") {
                adresseSelectionnee = adresseConfirmee
                RechercheAdresseService.sauvegarderLieu(adresseConfirmee)
                dismiss()
            }
            .disabled(adresseConfirmee.isEmpty)
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
    }

    // MARK: - Actions

    /// Sélection depuis l'autocomplétion → coordonnées via MKLocalSearch
    private func selectionnerSuggestion(_ s: MKLocalSearchCompletion) {
        let adresse = [s.title, s.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
        texteRecherche = adresse
        afficherSuggestions = false
        enGeocoding = true

        let req = MKLocalSearch.Request(completion: s)
        MKLocalSearch(request: req).start { resp, _ in
            Task { @MainActor in
                enGeocoding = false
                guard let item = resp?.mapItems.first else {
                    adresseConfirmee = adresse
                    return
                }
                let coord = item.location.coordinate
                coordonneePin = coord
                adresseConfirmee = adresse
                centrerCarte(sur: coord, zoom: 0.01)
            }
        }
    }

    /// Clic sur la carte → géocodage inverse
    private func geocoderCoordonnee(_ coord: CLLocationCoordinate2D) {
        requeteReverseGeocoding?.cancel()
        enGeocoding = true
        adresseConfirmee = ""
        guard let requete = MKReverseGeocodingRequest(location: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) else {
            enGeocoding = false
            return
        }
        requeteReverseGeocoding = requete
        requete.getMapItems { items, _ in
            Task { @MainActor in
                enGeocoding = false
                guard let item = items?.first else { return }
                let adresse = item.address?.fullAddress ?? item.name ?? ""
                adresseConfirmee = adresse
                texteRecherche = adresse
            }
        }
    }

    /// Centrage initial sur l'adresse déjà saisie
    private func centrerSurAdresse(_ adresse: String) {
        guard let requete = MKGeocodingRequest(addressString: adresse) else { return }
        requete.getMapItems { items, _ in
            Task { @MainActor in
                guard let item = items?.first else { return }
                let coord = item.location.coordinate
                coordonneePin = coord
                centrerCarte(sur: coord, zoom: 0.01)
            }
        }
    }

    private func centrerCarte(sur coord: CLLocationCoordinate2D, zoom: Double) {
        withAnimation(.easeInOut(duration: 0.4)) {
            position = .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom)
            ))
        }
    }

}
