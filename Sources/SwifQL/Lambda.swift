//
//  Lambda.swift
//  SwifQL
//

import Foundation

/// The structured SQL lambda value passed to the dialect rendering boundary.
/// Parameter identities and body parts remain separate from concrete lambda
/// punctuation so downstream dialects can choose their own grammar.
public struct SQLPartLambda: SQLPart {
    public let parameters: [SQLLambda.Parameter]
    public let body: [SQLPart]

    public init(
        parameters: [SQLLambda.Parameter],
        body: [SQLPart]
    ) {
        self.parameters = parameters
        self.body = body
    }
}

public struct SQLLambda: SQLable {
    public struct Parameter: SQLable {
        private let column: SQLPartColumn

        public let name: String

        fileprivate init(_ name: String) {
            self.name = name
            column = SQLPartColumn(name)
        }

        public var parts: [SQLPart] {
            [column]
        }
    }

    public let parts: [SQLPart]

    public init(_ name: String, body: (Parameter) -> SQLable) {
        let parameter = Parameter(name)
        self.init(parameters: [parameter], body: body(parameter).parts)
    }

    public init(_ first: String, _ second: String, body: (Parameter, Parameter) -> SQLable) {
        let firstParameter = Parameter(first)
        let secondParameter = Parameter(second)
        self.init(
            parameters: [firstParameter, secondParameter],
            body: body(firstParameter, secondParameter).parts
        )
    }

    private init(parameters: [Parameter], body: [SQLPart]) {
        self.parts = [SQLPartLambda(parameters: parameters, body: body)]
    }
}
