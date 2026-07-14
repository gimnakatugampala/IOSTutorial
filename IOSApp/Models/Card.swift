import Foundation

struct Card: Identifiable {
    let id: Int
    var isLit: Bool = false
    /// A lit card can occasionally roll "golden" — worth bonus points if tapped in time.
    var isGolden: Bool = false
}
