import SwiftUI

public protocol AccessibleValue {
    var accessibilityText: String { get }
}

public protocol SizeIdentifiable {
    var sizeIdentifier: AnyHashable { get }
}
