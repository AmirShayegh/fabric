import Foundation

public enum FabricGraphLayoutEngine {
    public struct Config {
        public let nodeWidth: CGFloat
        public let nodeHeight: CGFloat
        public let layerGap: CGFloat
        public let nodeGap: CGFloat
        public let dummySlotHeight: CGFloat
        public let componentGap: CGFloat
        public let padding: CGFloat

        public init(
            nodeWidth: CGFloat,
            nodeHeight: CGFloat,
            layerGap: CGFloat,
            nodeGap: CGFloat,
            dummySlotHeight: CGFloat = 8,
            componentGap: CGFloat = 40,
            padding: CGFloat = 20
        ) {
            self.nodeWidth = nodeWidth
            self.nodeHeight = nodeHeight
            self.layerGap = layerGap
            self.nodeGap = nodeGap
            self.dummySlotHeight = dummySlotHeight
            self.componentGap = componentGap
            self.padding = padding
        }
    }

    public struct EdgeKey: Hashable {
        public let source: String
        public let target: String

        public init(source: String, target: String) {
            self.source = source
            self.target = target
        }
    }

    public struct LayoutResult {
        public let nodePositions: [String: CGPoint]
        public let edgeRoutes: [EdgeKey: [CGPoint]]
        public let totalSize: CGSize

        public init(nodePositions: [String: CGPoint], edgeRoutes: [EdgeKey: [CGPoint]], totalSize: CGSize) {
            self.nodePositions = nodePositions
            self.edgeRoutes = edgeRoutes
            self.totalSize = totalSize
        }
    }

    public static func layout(
        layers: [[String]],
        edges: [(source: String, target: String)],
        config: Config
    ) -> LayoutResult {
        guard !layers.isEmpty else {
            return LayoutResult(nodePositions: [:], edgeRoutes: [:], totalSize: CGSize(width: 300, height: 200))
        }

        var nodeLayer: [String: Int] = [:]
        for (i, layer) in layers.enumerated() {
            for name in layer { nodeLayer[name] = i }
        }

        let validEdges = edges.filter { nodeLayer[$0.source] != nil && nodeLayer[$0.target] != nil }
        let components = findComponents(layers: layers, edges: validEdges)

        var allPositions: [String: CGPoint] = [:]
        var allRoutes: [EdgeKey: [CGPoint]] = [:]
        var yOffset: CGFloat = config.padding
        var maxWidth: CGFloat = 0

        let sortedComponents = components.sorted { a, b in
            let aMaxLayer = a.map { nodeLayer[$0] ?? 0 }.max() ?? 0
            let bMaxLayer = b.map { nodeLayer[$0] ?? 0 }.max() ?? 0
            if aMaxLayer != bMaxLayer { return aMaxLayer > bMaxLayer }
            if a.count != b.count { return a.count > b.count }
            let aMinName = a.sorted().first ?? ""
            let bMinName = b.sorted().first ?? ""
            return aMinName < bMinName
        }

        for component in sortedComponents {
            let componentSet = Set(component)
            let componentLayers = layers.map { $0.filter { componentSet.contains($0) } }
            let componentEdges = validEdges.filter { componentSet.contains($0.source) && componentSet.contains($0.target) }

            let result = layoutComponent(
                layers: componentLayers,
                edges: componentEdges,
                nodeLayer: nodeLayer,
                config: config,
                yOffset: yOffset
            )

            for (k, v) in result.positions { allPositions[k] = v }
            for (k, v) in result.routes { allRoutes[k] = v }
            yOffset = result.maxY + config.componentGap
            maxWidth = max(maxWidth, result.maxX)
        }

        let totalWidth = max(maxWidth + config.padding, 300)
        let totalHeight = max(yOffset - config.componentGap + config.padding, 200)

        return LayoutResult(
            nodePositions: allPositions,
            edgeRoutes: allRoutes,
            totalSize: CGSize(width: totalWidth, height: totalHeight)
        )
    }

    // MARK: - Component Detection

    private static func findComponents(layers: [[String]], edges: [(source: String, target: String)]) -> [[String]] {
        let allNodes = Set(layers.flatMap { $0 })
        var adjacency: [String: Set<String>] = [:]
        for name in allNodes { adjacency[name] = [] }
        for edge in edges {
            adjacency[edge.source, default: []].insert(edge.target)
            adjacency[edge.target, default: []].insert(edge.source)
        }

        var visited: Set<String> = []
        var components: [[String]] = []

        for node in allNodes.sorted() {
            guard !visited.contains(node) else { continue }
            var component: Set<String> = []
            var queue = [node]
            while !queue.isEmpty {
                let current = queue.removeFirst()
                guard !component.contains(current) else { continue }
                component.insert(current)
                visited.insert(current)
                for neighbor in (adjacency[current] ?? []).sorted() where !component.contains(neighbor) {
                    queue.append(neighbor)
                }
            }
            components.append(component.sorted())
        }
        return components
    }

    // MARK: - Per-Component Layout

    private struct ComponentResult {
        let positions: [String: CGPoint]
        let routes: [EdgeKey: [CGPoint]]
        let maxX: CGFloat
        let maxY: CGFloat
    }

    private static func layoutComponent(
        layers: [[String]],
        edges: [(source: String, target: String)],
        nodeLayer: [String: Int],
        config: Config,
        yOffset: CGFloat
    ) -> ComponentResult {
        let layerCount = layers.count

        var augmented = layers.map { $0 }
        var dummySet: Set<String> = []
        var dummyChains: [EdgeKey: [String]] = [:]

        for edge in edges {
            guard let sLayer = nodeLayer[edge.source], let tLayer = nodeLayer[edge.target] else { continue }
            let span = tLayer - sLayer
            if span <= 1 { continue }

            var chain: [String] = []
            for intermediate in (sLayer + 1)..<tLayer {
                let dummy = "__d_\(edge.source)_\(edge.target)_L\(intermediate)"
                augmented[intermediate].append(dummy)
                dummySet.insert(dummy)
                chain.append(dummy)
            }
            dummyChains[EdgeKey(source: edge.source, target: edge.target)] = chain
        }

        var adjacentEdges: [(source: String, target: String)] = []
        for edge in edges {
            guard let sL = nodeLayer[edge.source], let tL = nodeLayer[edge.target] else { continue }
            if tL - sL == 1 {
                adjacentEdges.append(edge)
            } else if tL - sL > 1 {
                let key = EdgeKey(source: edge.source, target: edge.target)
                if let chain = dummyChains[key] {
                    adjacentEdges.append((source: edge.source, target: chain[0]))
                    for i in 0..<(chain.count - 1) {
                        adjacentEdges.append((source: chain[i], target: chain[i + 1]))
                    }
                    adjacentEdges.append((source: chain.last!, target: edge.target))
                }
            }
        }

        var orderByLayer = augmented
        orderByLayer = medianCrossingReduction(orderByLayer: orderByLayer, adjacentEdges: adjacentEdges, layerCount: layerCount)

        var positions: [String: CGPoint] = [:]
        var slotPositions: [String: CGPoint] = [:]
        var maxX: CGFloat = 0

        let layerHeights = orderByLayer.map { layer in
            guard !layer.isEmpty else { return CGFloat(0) }
            let slotTotal = layer.reduce(CGFloat(0)) { total, nodeName in
                total + (dummySet.contains(nodeName) ? config.dummySlotHeight : config.nodeHeight)
            }
            return slotTotal + CGFloat(max(layer.count - 1, 0)) * config.nodeGap
        }
        let componentHeight = max(layerHeights.max() ?? 0, config.nodeHeight)

        for (layerIdx, layer) in orderByLayer.enumerated() {
            let x = config.padding + CGFloat(layerIdx) * (config.nodeWidth + config.layerGap) + config.nodeWidth / 2
            maxX = max(maxX, x + config.nodeWidth / 2)

            let layerHeight = layerHeights[layerIdx]
            var y = yOffset + max(0, (componentHeight - layerHeight) / 2)
            for nodeName in layer {
                let isDummy = dummySet.contains(nodeName)
                let slotHeight = isDummy ? config.dummySlotHeight : config.nodeHeight
                let centerY = y + slotHeight / 2

                if isDummy {
                    slotPositions[nodeName] = CGPoint(x: x, y: centerY)
                } else {
                    let pos = CGPoint(x: x, y: centerY)
                    positions[nodeName] = pos
                    slotPositions[nodeName] = pos
                }

                y += slotHeight + config.nodeGap
            }
        }

        var routes: [EdgeKey: [CGPoint]] = [:]
        for edge in edges {
            let key = EdgeKey(source: edge.source, target: edge.target)
            guard let sourcePos = slotPositions[edge.source],
                  let targetPos = slotPositions[edge.target] else { continue }

            var points: [CGPoint] = []
            let sourcePort = portPosition(
                node: edge.source, pos: sourcePos, side: .right,
                edges: edges, slotPositions: slotPositions, config: config,
                currentEdgeTarget: edge.target, dummySet: dummySet, dummyChains: dummyChains
            )
            points.append(sourcePort)

            if let chain = dummyChains[key] {
                for dummy in chain {
                    if let dPos = slotPositions[dummy] {
                        points.append(dPos)
                    }
                }
            }

            let targetPort = portPosition(
                node: edge.target, pos: targetPos, side: .left,
                edges: edges, slotPositions: slotPositions, config: config,
                currentEdgeSource: edge.source, dummySet: dummySet, dummyChains: dummyChains
            )
            points.append(targetPort)

            routes[key] = points
        }

        return ComponentResult(positions: positions, routes: routes, maxX: maxX, maxY: yOffset + componentHeight)
    }

    // MARK: - Median Crossing Reduction

    private static func medianCrossingReduction(
        orderByLayer: [[String]],
        adjacentEdges: [(source: String, target: String)],
        layerCount: Int
    ) -> [[String]] {
        var order = orderByLayer
        var bestOrder = order
        var bestCrossings = countCrossings(order: order, adjacentEdges: adjacentEdges)

        for _ in 0..<4 {
            for layerIdx in 1..<layerCount {
                order[layerIdx] = sortByMedian(
                    layer: order[layerIdx],
                    neighborLayer: order[layerIdx - 1],
                    adjacentEdges: adjacentEdges,
                    direction: .up
                )
            }
            for layerIdx in stride(from: layerCount - 2, through: 0, by: -1) {
                order[layerIdx] = sortByMedian(
                    layer: order[layerIdx],
                    neighborLayer: order[layerIdx + 1],
                    adjacentEdges: adjacentEdges,
                    direction: .down
                )
            }
            let crossings = countCrossings(order: order, adjacentEdges: adjacentEdges)
            if crossings < bestCrossings {
                bestCrossings = crossings
                bestOrder = order
            }
        }
        return bestOrder
    }

    private enum Direction { case up, down }

    private static func sortByMedian(
        layer: [String],
        neighborLayer: [String],
        adjacentEdges: [(source: String, target: String)],
        direction: Direction
    ) -> [String] {
        let neighborPos = Dictionary(uniqueKeysWithValues: neighborLayer.enumerated().map { ($1, $0) })

        return layer.sorted { a, b in
            let ma = medianNeighborPos(node: a, neighborPos: neighborPos, edges: adjacentEdges, direction: direction)
            let mb = medianNeighborPos(node: b, neighborPos: neighborPos, edges: adjacentEdges, direction: direction)
            if let ma, let mb { if ma != mb { return ma < mb } }
            if ma != nil && mb == nil { return true }
            if ma == nil && mb != nil { return false }
            return a < b
        }
    }

    private static func medianNeighborPos(
        node: String,
        neighborPos: [String: Int],
        edges: [(source: String, target: String)],
        direction: Direction
    ) -> Double? {
        var positions: [Int] = []
        for edge in edges {
            if direction == .up {
                if edge.target == node, let pos = neighborPos[edge.source] { positions.append(pos) }
            } else {
                if edge.source == node, let pos = neighborPos[edge.target] { positions.append(pos) }
            }
        }
        guard !positions.isEmpty else { return nil }
        positions.sort()
        let mid = positions.count / 2
        return positions.count % 2 == 1 ? Double(positions[mid]) : Double(positions[mid - 1] + positions[mid]) / 2.0
    }

    private static func countCrossings(
        order: [[String]],
        adjacentEdges: [(source: String, target: String)]
    ) -> Int {
        var total = 0
        for layerIdx in 0..<(order.count - 1) {
            let topPos = Dictionary(uniqueKeysWithValues: order[layerIdx].enumerated().map { ($1, $0) })
            let botPos = Dictionary(uniqueKeysWithValues: order[layerIdx + 1].enumerated().map { ($1, $0) })
            var segments: [(Int, Int)] = []
            for edge in adjacentEdges {
                if let s = topPos[edge.source], let t = botPos[edge.target] {
                    segments.append((s, t))
                }
            }
            for i in 0..<segments.count {
                for j in (i + 1)..<segments.count {
                    if (segments[i].0 < segments[j].0 && segments[i].1 > segments[j].1) ||
                       (segments[i].0 > segments[j].0 && segments[i].1 < segments[j].1) {
                        total += 1
                    }
                }
            }
        }
        return total
    }

    // MARK: - Port Assignment

    private enum Side { case left, right }

    private static func portPosition(
        node: String,
        pos: CGPoint,
        side: Side,
        edges: [(source: String, target: String)],
        slotPositions: [String: CGPoint],
        config: Config,
        currentEdgeTarget: String? = nil,
        currentEdgeSource: String? = nil,
        dummySet: Set<String>,
        dummyChains: [EdgeKey: [String]]
    ) -> CGPoint {
        if dummySet.contains(node) { return pos }

        let connectedNodes: [String]
        if side == .right {
            var targets: [String] = []
            for edge in edges where edge.source == node {
                let firstHop: String
                let key = EdgeKey(source: edge.source, target: edge.target)
                if let chain = dummyChains[key], let first = chain.first {
                    firstHop = first
                } else {
                    firstHop = edge.target
                }
                targets.append(firstHop)
            }
            targets.sort { (slotPositions[$0]?.y ?? 0) < (slotPositions[$1]?.y ?? 0) }
            connectedNodes = targets
        } else {
            var sources: [String] = []
            for edge in edges where edge.target == node {
                let lastHop: String
                let key = EdgeKey(source: edge.source, target: edge.target)
                if let chain = dummyChains[key], let last = chain.last {
                    lastHop = last
                } else {
                    lastHop = edge.source
                }
                sources.append(lastHop)
            }
            sources.sort { (slotPositions[$0]?.y ?? 0) < (slotPositions[$1]?.y ?? 0) }
            connectedNodes = sources
        }

        let count = connectedNodes.count
        guard count > 1 else { return CGPoint(x: side == .right ? pos.x + config.nodeWidth / 2 : pos.x - config.nodeWidth / 2, y: pos.y) }

        let usable = config.nodeHeight * 0.6
        let edgeKey: String?
        if side == .right {
            if let t = currentEdgeTarget {
                let key = EdgeKey(source: node, target: t)
                if let chain = dummyChains[key], let first = chain.first {
                    edgeKey = first
                } else {
                    edgeKey = t
                }
            } else { edgeKey = nil }
        } else {
            if let s = currentEdgeSource {
                let key = EdgeKey(source: s, target: node)
                if let chain = dummyChains[key], let last = chain.last {
                    edgeKey = last
                } else {
                    edgeKey = s
                }
            } else { edgeKey = nil }
        }

        let idx = connectedNodes.firstIndex(of: edgeKey ?? "") ?? 0
        let offset = -usable / 2 + usable * CGFloat(idx) / CGFloat(count - 1)
        let x = side == .right ? pos.x + config.nodeWidth / 2 : pos.x - config.nodeWidth / 2
        return CGPoint(x: x, y: pos.y + offset)
    }
}
