import Foundation

enum Player: String, Codable, CaseIterable {
    case black
    case white

    var opponent: Player {
        switch self {
        case .black:
            return .white
        case .white:
            return .black
        }
    }

    var disc: CellState {
        switch self {
        case .black:
            return .black
        case .white:
            return .white
        }
    }
}

enum CellState: String, Codable, Equatable {
    case empty
    case black
    case white

    var owner: Player? {
        switch self {
        case .black:
            return .black
        case .white:
            return .white
        case .empty:
            return nil
        }
    }
}

struct GameState: Equatable {
    static let boardSize = 8

    var board: [CellState]
    var currentPlayer: Player

    init(board: [CellState], currentPlayer: Player) {
        self.board = board
        self.currentPlayer = currentPlayer
    }
}

private let directions: [(row: Int, col: Int)] = [
    (-1, -1), (-1, 0), (-1, 1),
    (0, -1), /*self*/ (0, 1),
    (1, -1), (1, 0), (1, 1)
]

func computeLegalMoves(for state: GameState) -> [Int] {
    guard !state.board.isEmpty else { return [] }

    return state.board.indices.compactMap { index in
        guard state.board[index] == .empty else { return nil }
        let flips = discsToFlip(from: index, for: state.currentPlayer, board: state.board, boardSize: GameState.boardSize)
        return flips.isEmpty ? nil : index
    }
}

func applyMove(state: GameState, at index: Int) -> GameState? {
    guard state.board.indices.contains(index), state.board[index] == .empty else { return nil }

    let flips = discsToFlip(from: index, for: state.currentPlayer, board: state.board, boardSize: GameState.boardSize)
    guard !flips.isEmpty else { return nil }

    var nextBoard = state.board
    nextBoard[index] = state.currentPlayer.disc
    flips.forEach { nextBoard[$0] = state.currentPlayer.disc }

    return GameState(board: nextBoard, currentPlayer: state.currentPlayer)
}

let initialStateA: GameState = {
    var board = Array(repeating: CellState.empty, count: GameState.boardSize * GameState.boardSize)

    let middle = GameState.boardSize / 2
    let topLeft = (middle - 1) * GameState.boardSize + (middle - 1)
    let topRight = (middle - 1) * GameState.boardSize + middle
    let bottomLeft = middle * GameState.boardSize + (middle - 1)
    let bottomRight = middle * GameState.boardSize + middle

    board[topLeft] = .white
    board[topRight] = .black
    board[bottomLeft] = .black
    board[bottomRight] = .white

    return GameState(board: board, currentPlayer: .black)
}()

private func discsToFlip(from index: Int, for player: Player, board: [CellState], boardSize: Int) -> [Int] {
    let row = index / boardSize
    let col = index % boardSize
    var captured: [Int] = []

    for direction in directions {
        var currentRow = row + direction.row
        var currentCol = col + direction.col
        var path: [Int] = []

        while currentRow >= 0, currentRow < boardSize, currentCol >= 0, currentCol < boardSize {
            let currentIndex = currentRow * boardSize + currentCol
            let cell = board[currentIndex]

            if cell == .empty {
                path.removeAll()
                break
            }

            if cell.owner == player {
                captured.append(contentsOf: path)
                break
            }

            path.append(currentIndex)
            currentRow += direction.row
            currentCol += direction.col
        }
    }

    return captured
}
