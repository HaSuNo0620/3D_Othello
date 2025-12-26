import XCTest
@testable import CoreLogic

final class CoreLogicTests: XCTestCase {
    func testInitialStateScore() {
        let board = Board.initialStateA()
        let score = Board.score(board: board)
        XCTAssertEqual(Board.volume, 64)
        XCTAssertEqual(score.black, 4)
        XCTAssertEqual(score.white, 4)
        XCTAssertEqual(score.empty, 56)
    }

    func testDirectionsCount() {
        XCTAssertEqual(Board.directions.count, 26)
    }
}
