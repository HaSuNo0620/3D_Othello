#if canImport(Combine)
import Combine
#endif

@MainActor
final class GameViewModel: ObservableObject {
    @Published var board: [CellState]
    @Published var currentPlayer: Player
    @Published var legalMoves: [Int]
    @Published var message: String
    @Published var gameOver: Bool

    init(initialState: GameState = initialStateA) {
        board = initialState.board
        currentPlayer = initialState.currentPlayer
        legalMoves = computeLegalMoves(for: initialState)
        message = ""
        gameOver = false
    }

    func makeMove(_ index: Int) {
        guard !gameOver else { return }
        guard legalMoves.contains(index) else { return }

        let state = GameState(board: board, currentPlayer: currentPlayer)
        guard let updatedState = applyMove(state: state, at: index) else { return }

        board = updatedState.board

        var nextPlayer = currentPlayer.opponent
        var nextLegalMoves = computeLegalMoves(for: GameState(board: board, currentPlayer: nextPlayer))

        if nextLegalMoves.isEmpty {
            message = "Pass"
            nextPlayer = currentPlayer
            nextLegalMoves = computeLegalMoves(for: GameState(board: board, currentPlayer: nextPlayer))
        } else {
            message = ""
        }

        currentPlayer = nextPlayer
        legalMoves = nextLegalMoves

        evaluateGameOver()
    }

    func restart() {
        board = initialStateA.board
        currentPlayer = initialStateA.currentPlayer
        legalMoves = computeLegalMoves(for: initialStateA)
        message = ""
        gameOver = false
    }

    private func evaluateGameOver() {
        let currentMoves = legalMoves
        let opponentMoves = computeLegalMoves(for: GameState(board: board, currentPlayer: currentPlayer.opponent))
        let noEmptySpaces = !board.contains(.empty)

        guard noEmptySpaces || (currentMoves.isEmpty && opponentMoves.isEmpty) else { return }

        let blackCount = board.filter { $0 == .black }.count
        let whiteCount = board.filter { $0 == .white }.count
        legalMoves = []
        gameOver = true

        if blackCount > whiteCount {
            message = "Black wins \(blackCount)-\(whiteCount)"
        } else if whiteCount > blackCount {
            message = "White wins \(whiteCount)-\(blackCount)"
        } else {
            message = "Draw \(blackCount)-\(whiteCount)"
        }
    }
}
