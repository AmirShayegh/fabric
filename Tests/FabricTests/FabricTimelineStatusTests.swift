import XCTest
@testable import Fabric

final class FabricTimelineStatusTests: XCTestCase {

    private func item(_ id: String, _ status: FabricTimelineItem.Status? = nil) -> FabricTimelineItem {
        FabricTimelineItem(id: id, timestamp: "", title: id, status: status)
    }

    // MARK: - Legacy mode

    func test_returnsNilWhenAllStatusesAreNil_legacyMode() {
        let items = [item("a"), item("b"), item("c")]
        XCTAssertNil(resolveExplicitTimelineStatuses(items))
    }

    func test_returnsNilForEmptyItems() {
        XCTAssertNil(resolveExplicitTimelineStatuses([]))
    }

    // MARK: - Explicit mode basic cases

    func test_returnsExplicitStatusesWhenAllSet() {
        let items = [
            item("a", .completed),
            item("b", .current),
            item("c", .future)
        ]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(result?.statuses, [.completed, .current, .future])
        XCTAssertEqual(result?.issues, TimelineStatusResolutionIssues.none)
    }

    func test_handlesAllFourCases() {
        let items = [
            item("a", .completed),
            item("b", .inProgress),
            item("c", .current),
            item("d", .future)
        ]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(result?.statuses, [.completed, .inProgress, .current, .future])
        XCTAssertEqual(result?.issues, TimelineStatusResolutionIssues.none)
    }

    // MARK: - Multi-current normalization (the major finding from review)

    func test_multipleCurrentItems_firstStaysCurrent_restCoerceToInProgress() {
        let items = [
            item("a", .current),
            item("b", .completed),
            item("c", .current), // extra
            item("d", .current)  // extra
        ]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(result?.statuses, [.current, .completed, .inProgress, .inProgress])
        XCTAssertEqual(result?.issues.extraCurrentCount, 2)
        XCTAssertEqual(result?.issues.missingStatusCount, 0)
    }

    func test_noCurrent_doesNotTriggerCoercion() {
        let items = [item("a", .completed), item("b", .inProgress)]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(result?.statuses, [.completed, .inProgress])
        XCTAssertEqual(result?.issues, TimelineStatusResolutionIssues.none)
    }

    // MARK: - Mixed-mode (caller bug: some items have status, others nil)

    func test_mixedMode_nilItemsCoerceToFuture_reported() {
        let items = [
            item("a", .completed),
            item("b", nil),
            item("c", .current),
            item("d", nil)
        ]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(result?.statuses, [.completed, .future, .current, .future])
        XCTAssertEqual(result?.issues.missingStatusCount, 2)
        XCTAssertEqual(result?.issues.extraCurrentCount, 0)
    }

    // MARK: - Non-linear roadmap shape (the Mac app scenario)

    func test_nonLinearRoadmap_phase0inprogress_phase1completedIsValid() {
        // Mirrors the broker project's shape: phase 0 is the primary
        // current, phases 1-3 already complete, phases 4-5 also active
        // (render as .inProgress, no pulse).
        let items = [
            item("p0", .current),
            item("p1", .completed),
            item("p2", .completed),
            item("p3", .completed),
            item("p4", .inProgress),
            item("p5", .inProgress)
        ]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(
            result?.statuses,
            [.current, .completed, .completed, .completed, .inProgress, .inProgress]
        )
        XCTAssertEqual(result?.issues, TimelineStatusResolutionIssues.none)
    }

    // MARK: - Future adjacency

    func test_futureStateTransitions() {
        let items = [
            item("a", .completed),
            item("b", .future),
            item("c", .completed)
        ]
        let result = resolveExplicitTimelineStatuses(items)
        XCTAssertEqual(result?.statuses, [.completed, .future, .completed])
        XCTAssertEqual(result?.issues, TimelineStatusResolutionIssues.none)
    }
}
