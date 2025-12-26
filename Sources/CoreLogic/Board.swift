import Foundation

public enum Stone {
    public static let black = 1
    public static let white = -1
    public static let empty = 0
}

public struct Board {
    public static let size = 4
    public static let volume = size * size * size

    public static let directions: [(dx: Int, dy: Int, dz: Int)] = {
        var result: [(Int, Int, Int)] = []
        for dx in -1...1 {
            for dy in -1...1 {
                for dz in -1...1 {
                    if dx == 0 && dy == 0 && dz == 0 {
                        continue
                    }
                    result.append((dx, dy, dz))
                }
            }
        }
        return result
    }()

    @inline(__always)
    public static func xyzToIdx(x: Int, y: Int, z: Int) -> Int {
        z * size * size + y * size + x
    }

    @inline(__always)
    public static func idxToXYZ(_ idx: Int) -> (x: Int, y: Int, z: Int) {
        let z = idx / (size * size)
        let remainder = idx % (size * size)
        let y = remainder / size
        let x = remainder % size
        return (x, y, z)
    }

    @inline(__always)
    public static func inBounds(x: Int, y: Int, z: Int) -> Bool {
        (0..<size).contains(x) && (0..<size).contains(y) && (0..<size).contains(z)
    }

    @inline(__always)
    public static func get(board: [Int], x: Int, y: Int, z: Int) -> Int {
        let idx = xyzToIdx(x: x, y: y, z: z)
        return board[idx]
    }

    public static func set(board: [Int], x: Int, y: Int, z: Int, value: Int) -> [Int] {
        var next = board
        let idx = xyzToIdx(x: x, y: y, z: z)
        next[idx] = value
        return next
    }

    public static func getFlips(board: [Int], player: Int, x: Int, y: Int, z: Int) -> [Int] {
        guard inBounds(x: x, y: y, z: z) else { return [] }
        let startIdx = xyzToIdx(x: x, y: y, z: z)
        guard board[startIdx] == Stone.empty else { return [] }

        var flips: [Int] = []
        for direction in directions {
            var path: [Int] = []
            var cx = x + direction.dx
            var cy = y + direction.dy
            var cz = z + direction.dz

            while inBounds(x: cx, y: cy, z: cz) {
                let idx = xyzToIdx(x: cx, y: cy, z: cz)
                let cell = board[idx]

                if cell == -player {
                    path.append(idx)
                } else if cell == player {
                    flips.append(contentsOf: path)
                    break
                } else {
                    break
                }

                cx += direction.dx
                cy += direction.dy
                cz += direction.dz
            }
        }
        return flips
    }

    public static func getLegalMoves(board: [Int], player: Int) -> [(x: Int, y: Int, z: Int, flips: [Int])] {
        var moves: [(x: Int, y: Int, z: Int, flips: [Int])] = []
        for idx in 0..<volume {
            if board[idx] != Stone.empty {
                continue
            }
            let coordinate = idxToXYZ(idx)
            let flips = getFlips(board: board, player: player, x: coordinate.x, y: coordinate.y, z: coordinate.z)
            if !flips.isEmpty {
                moves.append((coordinate.x, coordinate.y, coordinate.z, flips))
            }
        }
        return moves
    }

    public static func applyMove(board: [Int], player: Int, x: Int, y: Int, z: Int) -> [Int] {
        let flips = getFlips(board: board, player: player, x: x, y: y, z: z)
        guard !flips.isEmpty else { return board }

        var next = board
        let idx = xyzToIdx(x: x, y: y, z: z)
        next[idx] = player
        for flipIdx in flips {
            next[flipIdx] = player
        }
        return next
    }

    public static func hasAnyMove(board: [Int], player: Int) -> Bool {
        !getLegalMoves(board: board, player: player).isEmpty
    }

    public static func isBoardFull(board: [Int]) -> Bool {
        !board.contains(where: { $0 == Stone.empty })
    }

    public static func isGameOver(board: [Int]) -> Bool {
        isBoardFull(board: board) || (!hasAnyMove(board: board, player: Stone.black) && !hasAnyMove(board: board, player: Stone.white))
    }

    public static func score(board: [Int]) -> (black: Int, white: Int, empty: Int) {
        var black = 0
        var white = 0
        var empty = 0
        for cell in board {
            if cell == Stone.black {
                black += 1
            } else if cell == Stone.white {
                white += 1
            } else {
                empty += 1
            }
        }
        return (black, white, empty)
    }

    public static func initialStateA() -> [Int] {
        var board = Array(repeating: Stone.empty, count: volume)
        for x in 1...2 {
            for y in 1...2 {
                for z in 1...2 {
                    let value = ((x + y + z) % 2 == 0) ? Stone.white : Stone.black
                    let idx = xyzToIdx(x: x, y: y, z: z)
                    board[idx] = value
                }
            }
        }
        return board
    }
}
