//
//  Functions+TextSearch.swift
//  SwifQL
//
//  Created by Mihael Isaev on 22.05.2020.
//

extension Fn.Name {
    public static let toTSVector: Self = .init("to_tsvector")
    @available(*, deprecated, renamed: "toTSVector")
    public static var to_tsvector: Self { .toTSVector }
    public static let toTSQuery: Self = .init("to_tsquery")
    @available(*, deprecated, renamed: "toTSQuery")
    public static var to_tsquery: Self { .toTSQuery }
    public static let plainToTSQuery: Self = .init("plainto_tsquery")
    @available(*, deprecated, renamed: "plainToTSQuery")
    public static var plainto_tsquery: Self { .plainToTSQuery }
    public static let tsRankCD: Self = .init("ts_rank_cd")
    @available(*, deprecated, renamed: "tsRankCD")
    public static var ts_rank_cd: Self { .tsRankCD }
}

extension Fn {
    /// PostgreSQL provides the function to_tsvector for converting a document to the tsvector data type.
    /// to_tsvector([ config regconfig, ] document text) returns tsvector
    /// # Example
    /// ```swift
    /// Fn.toTSVector("english", "a fat  cat sat on a mat - it ate a fat rats")
    /// ```
    /// # Result
    /// ```
    /// 'ate':9 'cat':3 'fat':2,11 'mat':7 'rat':12 'sat':4
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/textsearch-controls.html)
    public static func toTSVector(_ config: SQLable, _ text: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = config.parts
        if let text = text {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: text.parts)
        }
        return build(.toTSVector, body: parts)
    }

    @available(*, deprecated, renamed: "toTSVector(_:_:)")
    public static func to_tsvector(_ config: SQLable, _ text: SQLable? = nil) -> SQLable {
        toTSVector(config, text)
    }
    
    /// PostgreSQL provides to_tsquery function for converting a query to the tsquery data type.
    /// to_tsquery offers access to more features than plainto_tsquery, but is less forgiving about its input.
    /// to_tsquery([ config regconfig, ] querytext text) returns tsquery
    /// # Example
    /// ```swift
    /// Fn.toTSQuery("english", "The & Fat & Rats")
    /// ```
    /// # Result
    /// ```
    /// 'fat' & 'rat'
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/textsearch-controls.html)
    public static func toTSQuery(_ config: SQLable, _ text: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = config.parts
        if let text = text {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: text.parts)
        }
        return build(.toTSQuery, body: parts)
    }

    @available(*, deprecated, renamed: "toTSQuery(_:_:)")
    public static func to_tsquery(_ config: SQLable, _ text: SQLable? = nil) -> SQLable {
        toTSQuery(config, text)
    }
    
    /// `plainto_tsquery` transforms unformatted text querytext to tsquery
    /// plainto_tsquery([ config regconfig, ] querytext text) returns tsquery
    /// # Example
    /// ```swift
    /// Fn.plainToTSQuery("english", "The Fat Rats")
    /// ```
    /// # Result
    /// ```
    /// 'fat' & 'rat'
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.1/textsearch-controls.html)
    public static func plainToTSQuery(_ config: SQLable, _ text: SQLable? = nil) -> SQLable {
        var parts: [SQLPart] = config.parts
        if let text = text {
            parts.append(o: .comma)
            parts.append(o: .space)
            parts.append(contentsOf: text.parts)
        }
        return build(.plainToTSQuery, body: parts)
    }

    @available(*, deprecated, renamed: "plainToTSQuery(_:_:)")
    public static func plainto_tsquery(_ config: SQLable, _ text: SQLable? = nil) -> SQLable {
        plainToTSQuery(config, text)
    }
    
    /// PostgreSQL provides two predefined ranking functions, which take into account lexical, proximity,
    /// and structural information; that is, they consider how often the query terms appear in the document,
    /// how close together the terms are in the document, and how important is the part of the document where they occur.
    
    /// `ts_rank_rd` calculates the rank of the provided tsquery
    /// ts_rank_rd(vector tsvector, query tsquery [, normalization integer ]) returns tsquery
    /// # Example
    /// ```swift
    /// Fn.tsRankCD("rats", Fn.toTSQuery("The Fat Rats"))
    /// ```
    /// # Result
    /// ```
    /// ts_rank_cd("rats", to_tsquery('The Fat Rats'))
    /// ```
    /// [Learn more →](https://www.postgresql.org/docs/9.6/textsearch-controls.html#TEXTSEARCH-RANKING)
    public static func tsRankCD(_ vector: SQLable, _ query: SQLable) -> SQLable {
        var parts: [SQLPart] = vector.parts
        parts.append(o: .comma)
        parts.append(o: .space)
        parts.append(contentsOf: query.parts)
        return build(.tsRankCD, body: parts)
    }

    @available(*, deprecated, renamed: "tsRankCD(_:_:)")
    public static func ts_rank_cd(_ vector: SQLable, _ query: SQLable) -> SQLable {
        tsRankCD(vector, query)
    }
}
