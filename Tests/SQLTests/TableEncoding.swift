@testable import SQL
import Foundation
import Testing

@Suite("Table Encoding Tests")
struct TableEncodingTests: SwifQLTests {
    @Test("Test Pure")
    func pure() throws {
        let encodedData = try JSONEncoder().encode(PureTable())
        _ = try JSONDecoder().decode(PureStruct.self, from: encodedData)
    }
    
    @Test("Test With Optional Column")
    func withOptionalColumn() {
        #if swift(>=5.4)
        #expect(TableWithOptionalColumn().firstName == nil)
        #endif
    }
    
    @Test("Test With KeyPaths")
    func withKeyPaths() throws {
        let encodedData = try JSONEncoder().encode(KeyPathTable())
        _ = try JSONDecoder().decode(KeyPathStruct.self, from: encodedData)
    }
}

fileprivate struct PureStruct: Codable {
    let id: UUID
    let first_name: String
}

fileprivate final class PureTable: Table {
    @Column("id")
    var id: UUID
    
    @Column("first_name")
    var firstName: String

    init () {
        id = UUID()
        firstName = ""
    }
}

fileprivate final class TableWithOptionalColumn: Table {
    @Column("first_name")
    var firstName: String?

    init () {}
}

fileprivate struct KeyPathStruct: Codable {
    let id: UUID
    let firstName: String
}

fileprivate final class KeyPathTable: Table, KeyPathEncodable {
    @Column("id")
    var id: UUID
    
    @Column("first_name")
    var firstName: String

    init () {
        id = UUID()
        firstName = ""
    }
}
