import Foundation

enum MovementSuggestionService {
    static func enabledExercises(preferences: UserPreferences) -> [MovementExercise] {
        let enabledIDs = Set(preferences.movementExercisesEnabled)
        return MovementExercise.allCases.filter { enabledIDs.contains($0.rawValue) }
    }

    static func suggestion(preferences: UserPreferences) -> String? {
        let exercises = enabledExercises(preferences: preferences)
        guard !exercises.isEmpty else { return nil }
        if preferences.movementRandomSuggestion {
            return exercises.randomElement()?.title
        }
        return exercises.first?.title
    }
}
