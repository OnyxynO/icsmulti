import MapKit

/// Service d'autocomplétion d'adresses via MapKit
@Observable
final class RechercheAdresseService: NSObject, MKLocalSearchCompleterDelegate {
    @ObservationIgnored private let completer = MKLocalSearchCompleter()

    /// Texte de recherche — met à jour les suggestions automatiquement
    var recherche: String = "" {
        didSet {
            if recherche.count >= 3 {
                completer.queryFragment = recherche
            } else {
                suggestions = []
            }
        }
    }

    /// Suggestions d'adresses retournées par MapKit
    var suggestions: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        // Priorité sur la France métropolitaine
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    }

    // MARK: - MKLocalSearchCompleterDelegate

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.suggestions = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
        }
    }

    // MARK: - Historique des lieux

    private static let cleUserDefaults = "lieuxRecents"
    private static let maxLieux = 20

    /// Lieux récents correspondant à la recherche en cours
    var lieuxRecents: [String] {
        guard recherche.count >= 1 else { return [] }
        let terme = recherche.lowercased()
        return Self.chargerLieux().filter { $0.lowercased().contains(terme) }
    }

    /// Enregistre un lieu dans l'historique (dédupliqué, le plus récent en premier)
    static func sauvegarderLieu(_ lieu: String) {
        let lieuNettoye = lieu.trimmingCharacters(in: .whitespaces)
        guard !lieuNettoye.isEmpty else { return }
        var lieux = chargerLieux()
        lieux.removeAll { $0 == lieuNettoye }
        lieux.insert(lieuNettoye, at: 0)
        if lieux.count > maxLieux { lieux = Array(lieux.prefix(maxLieux)) }
        UserDefaults.standard.set(lieux, forKey: cleUserDefaults)
    }

    /// Charge l'historique des lieux
    static func chargerLieux() -> [String] {
        UserDefaults.standard.stringArray(forKey: cleUserDefaults) ?? []
    }

    // MARK: - Ouvrir dans Apple Plans

    /// Ouvre l'adresse dans Apple Plans
    static func ouvrirDansPlans(adresse: String) {
        let requete = adresse.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? adresse
        if let url = URL(string: "maps://?q=\(requete)") {
            NSWorkspace.shared.open(url)
        }
    }
}
