//
//  GenericTableSelector.swift
//  SwifQL
//
//  Created by Mihael Isaev on 31.01.2020.
//

extension Table {
    public static var select: TableSelector<Self> { .init() }
}

public class TableSelector<T: Table>: SQLable {
    public var parts: [SQLPart] { build() }
    
    var columns: [String] = []
    var exceptColumns: [String] = []

    // MARK: Columns
    
    public func columns<A>(_ a: KeyPath<T, A>) -> Self where A: ColumnRepresentable {
        columns.append(T.key(for: a))
        return self
    }
    
    public func columns<A, B>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        return self
    }
    
    public func columns<A, B, C>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        return self
    }
    
    public func columns<A, B, C, D>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        return self
    }
    
    public func columns<A, B, C, D, E>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        return self
    }
    
    public func columns<A, B, C, D, E, F>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M, N>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>,
        _ n: KeyPath<T, N>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable,
        N: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        columns.append(T.key(for: n))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>,
        _ n: KeyPath<T, N>,
        _ o: KeyPath<T, O>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable,
        N: ColumnRepresentable,
        O: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        columns.append(T.key(for: n))
        columns.append(T.key(for: o))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>,
        _ n: KeyPath<T, N>,
        _ o: KeyPath<T, O>,
        _ p: KeyPath<T, P>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable,
        N: ColumnRepresentable,
        O: ColumnRepresentable,
        P: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        columns.append(T.key(for: n))
        columns.append(T.key(for: o))
        columns.append(T.key(for: p))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>,
        _ n: KeyPath<T, N>,
        _ o: KeyPath<T, O>,
        _ p: KeyPath<T, P>,
        _ q: KeyPath<T, Q>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable,
        N: ColumnRepresentable,
        O: ColumnRepresentable,
        P: ColumnRepresentable,
        Q: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        columns.append(T.key(for: n))
        columns.append(T.key(for: o))
        columns.append(T.key(for: p))
        columns.append(T.key(for: q))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>,
        _ n: KeyPath<T, N>,
        _ o: KeyPath<T, O>,
        _ p: KeyPath<T, P>,
        _ q: KeyPath<T, Q>,
        _ r: KeyPath<T, R>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable,
        N: ColumnRepresentable,
        O: ColumnRepresentable,
        P: ColumnRepresentable,
        Q: ColumnRepresentable,
        R: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        columns.append(T.key(for: n))
        columns.append(T.key(for: o))
        columns.append(T.key(for: p))
        columns.append(T.key(for: q))
        columns.append(T.key(for: r))
        return self
    }
    
    public func columns<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(
        _ a: KeyPath<T, A>,
        _ b: KeyPath<T, B>,
        _ c: KeyPath<T, C>,
        _ d: KeyPath<T, D>,
        _ e: KeyPath<T, E>,
        _ f: KeyPath<T, F>,
        _ g: KeyPath<T, G>,
        _ h: KeyPath<T, H>,
        _ i: KeyPath<T, I>,
        _ j: KeyPath<T, J>,
        _ k: KeyPath<T, K>,
        _ l: KeyPath<T, L>,
        _ m: KeyPath<T, M>,
        _ n: KeyPath<T, N>,
        _ o: KeyPath<T, O>,
        _ p: KeyPath<T, P>,
        _ q: KeyPath<T, Q>,
        _ r: KeyPath<T, R>,
        _ s: KeyPath<T, S>
    ) -> Self where
        A: ColumnRepresentable,
        B: ColumnRepresentable,
        C: ColumnRepresentable,
        D: ColumnRepresentable,
        E: ColumnRepresentable,
        F: ColumnRepresentable,
        G: ColumnRepresentable,
        H: ColumnRepresentable,
        I: ColumnRepresentable,
        J: ColumnRepresentable,
        K: ColumnRepresentable,
        L: ColumnRepresentable,
        M: ColumnRepresentable,
        N: ColumnRepresentable,
        O: ColumnRepresentable,
        P: ColumnRepresentable,
        Q: ColumnRepresentable,
        R: ColumnRepresentable,
        S: ColumnRepresentable {
        columns.append(T.key(for: a))
        columns.append(T.key(for: b))
        columns.append(T.key(for: c))
        columns.append(T.key(for: d))
        columns.append(T.key(for: e))
        columns.append(T.key(for: f))
        columns.append(T.key(for: g))
        columns.append(T.key(for: h))
        columns.append(T.key(for: i))
        columns.append(T.key(for: j))
        columns.append(T.key(for: k))
        columns.append(T.key(for: l))
        columns.append(T.key(for: m))
        columns.append(T.key(for: n))
        columns.append(T.key(for: o))
        columns.append(T.key(for: p))
        columns.append(T.key(for: q))
        columns.append(T.key(for: r))
        columns.append(T.key(for: s))
        return self
    }
    
    // MARK: Except columns
    
    public func exceptColumn<Column>(_ column: KeyPath<T, Column>) -> Self where Column: ColumnRepresentable {
        exceptColumns.append(T.key(for: column))
        return self
    }
    
    // MARK: Building
    
    private func build() -> [SQLPart] {
        var query: SQLable = SQL
        if columns.count == 0 {
            if exceptColumns.count > 0 {
                var cols = T.init().columns.map { $0.name.label }
                if exceptColumns.count > 0 {
                    cols = cols.filter { !exceptColumns.contains($0) }
                }
                query = query.select(cols.map { Path.Table(T.tableName).column($0) })
            } else {
                query = query.select(T.table.*)
            }
        } else {
            var cols = columns
            if exceptColumns.count > 0 {
                cols = cols.filter { !exceptColumns.contains($0) }
            }
            query = query.select(cols.map { Path.Table(T.tableName).column($0) })
        }
        query = query.from(T.table)
        return query.parts
    }
}
