//
//  File.swift
//  
//
//  Created by Leonard Mehlig on 11.05.21.
//

import SwiftUI

public protocol AccessibleValue {
    var accessibilityText: String { get }
}

public protocol SizeIdentifiable {
    var sizeIdentifier: AnyHashable { get }
}
