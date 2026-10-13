public enum MouseSummary {
    /// Header text for the connected mice: the first name, plus a count when there are more.
    public static func title(for names: [String]) -> String {
        guard let first = names.first else { return "No mouse" }
        let name = first.isEmpty ? "Mouse" : first
        return names.count == 1 ? name : "\(name) +\(names.count - 1)"
    }
}
