import SwiftUI
import RealityKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
typealias PlatformColor = NSColor
#else
typealias PlatformColor = UIColor
#endif

/// 盤面の状態を提供するための最低限のプロトコル。
/// 既存の ViewModel があれば準拠させるだけで BoardScene に接続できる。
public protocol BoardSceneViewModel: ObservableObject {
    /// 盤の一辺のマス数。4x4x4 を前提に `(x-1.5, y-1.5, z-1.5) * spacing` で位置決めする。
    var dimension: Int { get }
    /// マス間隔（ワールド座標系のスケール）。
    var spacing: Float { get }
    /// 各マスの状態。添字は `x + y * dimension + z * dimension * dimension`。
    var boardCells: [CellState] { get }
    /// 合法手の一次元インデックス集合。
    var legalMoves: Set<Int> { get }
    /// 合法手をタップしたときに呼ばれる。
    func makeMove(_ index: Int)
}

/// 盤面の石状態。
public enum CellState {
    case empty
    case black
    case white
}

/// BoardScene の実装共通部。RealityView/ARView の両方から再利用する。
final class BoardSceneRenderer {
    private enum Constants {
        static let ringPrefix = "ring_"
        static let gridOriginOffset: Float = 1.5
    }

    private let anchor: AnchorEntity
    private let boardRoot = Entity()
    private let dimension: Int
    private let spacing: Float

    private var staticCellsBuilt = false
    private var cellEntities: [Int: ModelEntity] = [:]
    private var stoneEntities: [Int: ModelEntity] = [:]
    private(set) var ringEntities: [Int: ModelEntity] = [:]

    init(dimension: Int, spacing: Float) {
        self.dimension = dimension
        self.spacing = spacing
        self.anchor = AnchorEntity(world: .zero)
        anchor.addChild(boardRoot)
    }

    // RealityView 用の配置。
#if os(visionOS)
    func place(into content: RealityViewContent) {
        content.add(anchor)
    }
#endif

    // ARView 用の配置。
    func place(into arView: ARView) {
        if !arView.scene.anchors.contains(anchor) {
            arView.scene.addAnchor(anchor)
        }
    }

    /// ViewModel の状態に合わせて石と合法手リングを同期する。
    func sync(with viewModel: BoardSceneViewModel) {
        guard viewModel.boardCells.count >= dimension * dimension * dimension else { return }
        buildStaticCellsIfNeeded()
        updateStones(board: viewModel.boardCells)
        updateRings(legalMoves: viewModel.legalMoves)
    }

    /// タップ対象が合法手リングなら ViewModel に通知する。
    func handleTap(on entity: Entity, viewModel: BoardSceneViewModel) {
        guard let index = ringIndex(from: entity) else { return }
        viewModel.makeMove(index)
    }

    // MARK: - Private

    private func buildStaticCellsIfNeeded() {
        guard !staticCellsBuilt else { return }
        staticCellsBuilt = true

        let cellSize = spacing * 0.9
        let cellHeight = spacing * 0.05
        let cellMesh = MeshResource.generateBox(size: [cellSize, cellHeight, cellSize])
        let cellMaterial = SimpleMaterial(color: PlatformColor.gray.withAlphaComponent(0.6), isMetallic: false)

        for index in 0..<(dimension * dimension * dimension) {
            let cell = ModelEntity(mesh: cellMesh, materials: [cellMaterial])
            cell.position = position(for: index)
            // セル枠はヒット対象にしない。
            cell.components[CollisionComponent.self] = nil
            cell.name = "cell_\(index)"
            cellEntities[index] = cell
            boardRoot.addChild(cell)
        }
    }

    private func updateStones(board: [CellState]) {
        for index in 0..<(dimension * dimension * dimension) {
            switch board[index] {
            case .empty:
                if let stone = stoneEntities.removeValue(forKey: index) {
                    stone.removeFromParent()
                }
            case .black, .white:
                let existing = stoneEntities[index]
                let desiredColor: PlatformColor = board[index] == .black ? .black : .white
                if let stone = existing {
                    stone.model?.materials = [SimpleMaterial(color: desiredColor, isMetallic: true)]
                } else {
                    let stone = makeStone(color: desiredColor)
                    stone.position = position(for: index)
                    stoneEntities[index] = stone
                    boardRoot.addChild(stone)
                }
            }
        }
    }

    private func updateRings(legalMoves: Set<Int>) {
        // 不要になったリングを削除。
        let obsolete = ringEntities.keys.filter { !legalMoves.contains($0) }
        obsolete.forEach { index in
            ringEntities[index]?.removeFromParent()
            ringEntities.removeValue(forKey: index)
        }

        // 新規リングを追加。
        for index in legalMoves where ringEntities[index] == nil {
            let ring = makeRing(index: index)
            ring.position = position(for: index)
            ringEntities[index] = ring
            boardRoot.addChild(ring)
        }
    }

    private func makeStone(color: PlatformColor) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: spacing * 0.35)
        let material = SimpleMaterial(color: color, isMetallic: true)
        let stone = ModelEntity(mesh: mesh, materials: [material])
        // 石もヒット対象から除外。
        stone.components[CollisionComponent.self] = nil
        stone.name = "stone"
        return stone
    }

    private func makeRing(index: Int) -> ModelEntity {
        let outerRadius = spacing * 0.45
        let innerRadius = spacing * 0.3
        let height = spacing * 0.02
        let mesh = MeshResource.generateTube(innerRadius: innerRadius, outerRadius: outerRadius, height: height)
        let material = SimpleMaterial(color: PlatformColor.green.withAlphaComponent(0.8), isMetallic: false)
        let ring = ModelEntity(mesh: mesh, materials: [material])
        ring.name = Constants.ringPrefix + "\(index)"
        // 合法手リングはヒット対象にするため CollisionComponent を保持。
        return ring
    }

    private func position(for index: Int) -> SIMD3<Float> {
        let (x, y, z) = gridCoordinate(for: index)
        let offset = Constants.gridOriginOffset
        return SIMD3<Float>(
            (Float(x) - offset) * spacing,
            (Float(y) - offset) * spacing,
            (Float(z) - offset) * spacing
        )
    }

    private func gridCoordinate(for index: Int) -> (Int, Int, Int) {
        let x = index % dimension
        let y = (index / dimension) % dimension
        let z = index / (dimension * dimension)
        return (x, y, z)
    }

    private func ringIndex(from entity: Entity) -> Int? {
        var current: Entity? = entity
        while let target = current {
            if target.name.hasPrefix(Constants.ringPrefix),
               let raw = target.name.split(separator: "_").last,
               let index = Int(raw) {
                return index
            }
            current = target.parent
        }
        return nil
    }
}

#if os(visionOS)
/// RealityView でボードを描画する実装。
public struct BoardScene<ViewModel: BoardSceneViewModel>: View {
    @ObservedObject private var viewModel: ViewModel
    private let renderer: BoardSceneRenderer

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        self.renderer = BoardSceneRenderer(dimension: viewModel.dimension, spacing: viewModel.spacing)
    }

    public var body: some View {
        RealityView { content in
            renderer.place(into: content)
            renderer.sync(with: viewModel)
        } update: { _ in
            renderer.sync(with: viewModel)
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    renderer.handleTap(on: value.entity, viewModel: viewModel)
                }
        )
    }
}
#else
/// ARView を用いた iOS/macOS 向けの実装。
public struct BoardScene<ViewModel: BoardSceneViewModel>: UIViewRepresentable {
    @ObservedObject private var viewModel: ViewModel
    private let renderer: BoardSceneRenderer

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        self.renderer = BoardSceneRenderer(dimension: viewModel.dimension, spacing: viewModel.spacing)
    }

    public func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        renderer.place(into: view)
        renderer.sync(with: viewModel)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        context.coordinator.arView = view
        return view
    }

    public func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.viewModel = viewModel
        renderer.sync(with: viewModel)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(renderer: renderer, viewModel: viewModel)
    }

    public final class Coordinator {
        private let renderer: BoardSceneRenderer
        fileprivate weak var arView: ARView?
        fileprivate var viewModel: ViewModel

        init(renderer: BoardSceneRenderer, viewModel: ViewModel) {
            self.renderer = renderer
            self.viewModel = viewModel
        }

        @objc
        func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = gesture.location(in: arView)
            guard let entity = arView.entity(at: location) else { return }
            renderer.handleTap(on: entity, viewModel: viewModel)
        }
    }
}
#endif
