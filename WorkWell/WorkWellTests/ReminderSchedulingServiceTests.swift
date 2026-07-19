import XCTest
@testable import WorkWell

final class ReminderSchedulingServiceTests: XCTestCase {
    private var calendar: Calendar { Calendar.current }

    func testFirstReminderStartsAfterIntervalAndStaysAnchoredToWorkStart() throws {
        var preferences = UserPreferences.default
        preferences.workStartTime = date(2026, 7, 19, 8, 0)
        preferences.workEndTime = date(2026, 7, 19, 17, 0)
        preferences.waterReminderIntervalMinutes = 20
        preferences.eyeReminderEnabled = false
        preferences.movementReminderEnabled = false

        let now = date(2026, 7, 19, 9, 7)
        let next = try XCTUnwrap(
            ReminderSchedulingService.nextScheduledDate(
                for: .water,
                preferences: preferences,
                from: now
            )
        )

        XCTAssertEqual(next, date(2026, 7, 19, 9, 20))
    }

    func testLunchOccurrencesAreSkipped() {
        var preferences = UserPreferences.default
        preferences.workStartTime = date(2026, 7, 19, 8, 0)
        preferences.workEndTime = date(2026, 7, 19, 17, 0)
        preferences.lunchStartTime = date(2026, 7, 19, 12, 0)
        preferences.lunchEndTime = date(2026, 7, 19, 13, 0)
        preferences.waterReminderIntervalMinutes = 30
        preferences.eyeReminderEnabled = false
        preferences.movementReminderEnabled = false

        let occurrences = ReminderSchedulingService.regularOccurrences(
            preferences: preferences,
            after: date(2026, 7, 19, 8, 0),
            through: date(2026, 7, 19, 17, 0)
        )

        XCTAssertFalse(occurrences.contains { hourAndMinute($0.date) == "12:00" })
        XCTAssertFalse(occurrences.contains { hourAndMinute($0.date) == "12:30" })
        XCTAssertTrue(occurrences.contains { hourAndMinute($0.date) == "13:00" })
    }

    func testOvernightWorkWindowIncludesFollowingMorning() {
        var preferences = UserPreferences.default
        preferences.workStartTime = date(2026, 7, 19, 22, 0)
        preferences.workEndTime = date(2026, 7, 19, 6, 0)
        preferences.waterReminderIntervalMinutes = 60
        preferences.eyeReminderEnabled = false
        preferences.movementReminderEnabled = false

        let occurrences = ReminderSchedulingService.regularOccurrences(
            preferences: preferences,
            after: date(2026, 7, 19, 21, 0),
            through: date(2026, 7, 20, 7, 0)
        )

        XCTAssertTrue(occurrences.contains { $0.date == date(2026, 7, 19, 23, 0) })
        XCTAssertTrue(occurrences.contains { $0.date == date(2026, 7, 20, 1, 0) })
        XCTAssertTrue(
            ReminderSchedulingService.isInsideWorkSchedule(
                date(2026, 7, 20, 1, 0),
                preferences: preferences
            )
        )
    }

    func testSimultaneousReminderTypesAreAllReturned() {
        var preferences = UserPreferences.default
        preferences.workStartTime = date(2026, 7, 19, 8, 0)
        preferences.workEndTime = date(2026, 7, 19, 17, 0)

        let occurrences = ReminderSchedulingService.regularOccurrences(
            preferences: preferences,
            after: date(2026, 7, 19, 10, 59),
            through: date(2026, 7, 19, 11, 0)
        )

        XCTAssertEqual(
            occurrences.map(\.type.rawValue).sorted(),
            ReminderType.allCases.map(\.rawValue).sorted()
        )
    }

    func testFiveMinuteScheduleIsNotTruncatedAt64Occurrences() {
        var preferences = UserPreferences.default
        preferences.workStartTime = date(2026, 7, 19, 8, 0)
        preferences.workEndTime = date(2026, 7, 19, 17, 0)
        preferences.waterReminderIntervalMinutes = 5
        preferences.eyeReminderEnabled = false
        preferences.movementReminderEnabled = false

        let occurrences = ReminderSchedulingService.regularOccurrences(
            preferences: preferences,
            after: date(2026, 7, 19, 8, 0),
            through: date(2026, 7, 19, 17, 0)
        )

        XCTAssertEqual(occurrences.count, 107)
        XCTAssertEqual(occurrences.last?.date, date(2026, 7, 19, 16, 55))
    }

    func testChangingIntervalImmediatelyChangesNextDate() throws {
        var preferences = UserPreferences.default
        preferences.workStartTime = date(2026, 7, 19, 8, 0)
        preferences.workEndTime = date(2026, 7, 19, 17, 0)
        preferences.eyeReminderEnabled = false
        preferences.movementReminderEnabled = false
        let now = date(2026, 7, 19, 9, 7)

        preferences.waterReminderIntervalMinutes = 60
        let hourly = try XCTUnwrap(
            ReminderSchedulingService.nextScheduledDate(for: .water, preferences: preferences, from: now)
        )
        preferences.waterReminderIntervalMinutes = 5
        let everyFiveMinutes = try XCTUnwrap(
            ReminderSchedulingService.nextScheduledDate(for: .water, preferences: preferences, from: now)
        )

        XCTAssertEqual(hourly, date(2026, 7, 19, 10, 0))
        XCTAssertEqual(everyFiveMinutes, date(2026, 7, 19, 9, 10))
    }

    func testNotificationTriggerComponentsContainTheFullDate() {
        let scheduledDate = date(2027, 2, 3, 14, 25)
        let components = ReminderSchedulingService.notificationDateComponents(for: scheduledDate)

        XCTAssertEqual(components.year, 2027)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 3)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 25)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }

    private func hourAndMinute(_ date: Date) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
