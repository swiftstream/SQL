@testable import SQL
import Testing

@Suite("Exists Tests")
struct ExistsTests: SwifQLTests {
    //MARK: - EXISTS
    
    @Test("Test Exists")
    func exists() {
        check(
            SwifQL.exists(1),
            .psql("EXISTS (1)"),
            .mysql("EXISTS (1)"),
            .duck("EXISTS (1)")
        )
    }
    
    //MARK: - NOT EXISTS
    
    @Test("Test Not Exists")
    func notExists() {
        check(
            SwifQL.notExists(1),
            .psql("NOT EXISTS (1)"),
            .mysql("NOT EXISTS (1)"),
            .duck("NOT EXISTS (1)")
        )
    }
    
    //MARK: - WHERE EXISTS
    
    @Test("Test Where Exists")
    func whereExists() {
        check(
            SwifQL.whereExists(1),
            .psql("WHERE EXISTS (1)"),
            .mysql("WHERE EXISTS (1)"),
            .duck("WHERE EXISTS (1)")
        )
    }
    
    //MARK: - WHERE NOT EXISTS
    
    @Test("Test Where Not Exists")
    func whereNotExists() {
        check(
            SwifQL.whereNotExists(1),
            .psql("WHERE NOT EXISTS (1)"),
            .mysql("WHERE NOT EXISTS (1)"),
            .duck("WHERE NOT EXISTS (1)")
        )
    }
}
