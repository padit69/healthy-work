import SwiftData
import XCTest
@testable import WorkWell

final class FeatureBehaviorTests: XCTestCase {
    func testWaterGoalUsesOverrideAndRejectsInvalidWeight() {
        var preferences = UserPreferences.default
        XCTAssertEqual(WaterService.dailyGoalMl(preferences: preferences), 1_920)

        preferences.gender = .male
        XCTAssertEqual(WaterService.dailyGoalMl(preferences: preferences), 2_112)

        preferences.waterGoalMlOverride = 2_500
        XCTAssertEqual(WaterService.dailyGoalMl(preferences: preferences), 2_500)

        preferences.waterGoalMlOverride = nil
        preferences.weightKg = -10
        XCTAssertEqual(WaterService.dailyGoalMl(preferences: preferences), 0)
    }

    func testWaterUnitConversionRoundTrips() {
        let ounces = WaterService.displayValue(forMl: 250, unit: .oz)
        XCTAssertEqual(ounces, 8.4535, accuracy: 0.001)
        XCTAssertEqual(WaterService.milliliters(from: ounces, unit: .oz), 250)
        XCTAssertEqual(
            WaterService.formattedAmount(250, unit: .oz, locale: Locale(identifier: "en_US_POSIX")),
            "8.5 oz"
        )
    }

    func testNonPositiveWaterRecordsAreIgnored() throws {
        let context = try makeContext()
        WaterService.addRecord(amountMl: 0, context: context)
        WaterService.addRecord(amountMl: -100, context: context)
        WaterService.addRecord(amountMl: 250, context: context)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WaterRecord>()), 1)
    }

    func testWaterCountTodayExcludesTomorrow() throws {
        let context = try makeContext()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        WaterService.addRecord(amountMl: 200, date: Date(), context: context)
        WaterService.addRecord(amountMl: 200, date: tomorrow, context: context)

        XCTAssertEqual(StatsService.waterCountToday(context: context), 1)
    }

    func testEyeRestSilentModeOnlySuppressesEyeRestSound() {
        var preferences = UserPreferences.default
        preferences.notificationSound = true
        preferences.eyeRestSilentMode = true

        XCTAssertFalse(ReminderSchedulingService.shouldPlaySound(for: .eyeRest, preferences: preferences))
        XCTAssertTrue(ReminderSchedulingService.shouldPlaySound(for: .water, preferences: preferences))

        preferences.eyeRestSilentMode = false
        XCTAssertTrue(ReminderSchedulingService.shouldPlaySound(for: .eyeRest, preferences: preferences))
    }

    func testMovementSuggestionUsesEnabledExercises() {
        var preferences = UserPreferences.default
        preferences.movementRandomSuggestion = false
        preferences.movementExercisesEnabled = [MovementExercise.neckRoll.rawValue, MovementExercise.walk.rawValue]

        XCTAssertEqual(
            MovementSuggestionService.enabledExercises(preferences: preferences),
            [.neckRoll, .walk]
        )
        XCTAssertEqual(
            MovementSuggestionService.suggestion(preferences: preferences),
            MovementExercise.neckRoll.title
        )
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([WaterRecord.self, ReminderLog.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
