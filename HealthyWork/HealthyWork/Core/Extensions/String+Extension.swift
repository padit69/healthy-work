import SwiftUI

extension String {
    var localizedByKey: String { String(localized: String.LocalizationValue(self))}
}
