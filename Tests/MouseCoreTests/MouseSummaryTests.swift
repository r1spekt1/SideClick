import Testing
@testable import MouseCore

@Suite struct MouseSummaryTests {
    @Test func noMouse() {
        #expect(MouseSummary.title(for: []) == "No mouse")
    }

    @Test func oneMouseShowsItsName() {
        #expect(MouseSummary.title(for: ["Mi Wireless Mouse"]) == "Mi Wireless Mouse")
    }

    @Test func moreMiceShowTheFirstNameAndACount() {
        #expect(MouseSummary.title(for: ["Mi Wireless Mouse", "MX Master 3"]) == "Mi Wireless Mouse +1")
        #expect(MouseSummary.title(for: ["A", "B", "C"]) == "A +2")
    }

    @Test func blankNameFallsBackToMouse() {
        #expect(MouseSummary.title(for: [""]) == "Mouse")
        #expect(MouseSummary.title(for: ["", "B"]) == "Mouse +1")
    }
}
