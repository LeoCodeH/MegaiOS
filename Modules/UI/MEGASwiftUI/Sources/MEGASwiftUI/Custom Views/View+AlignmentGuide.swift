//
//  View+AlignmentGuide.swift
//  MEGASwiftUI
//
//  Created by MacBook Pro on 2025/5/16.
//

import SwiftUI

public extension View {
    
    // mark closure 'computeValue' as @Sendable to avoid calling UIKit methods on non-main threads
    @inlinable nonisolated func fixed_alignmentGuide(_ g: HorizontalAlignment, computeValue: @escaping @Sendable (ViewDimensions) -> CGFloat) -> some View {
        self.alignmentGuide(g, computeValue: computeValue)
    }
    
    // mark closure 'computeValue' as @Sendable to avoid calling UIKit methods on non-main threads
    @inlinable nonisolated func fixed_alignmentGuide(_ g: VerticalAlignment, computeValue: @escaping @Sendable (ViewDimensions) -> CGFloat) -> some View {
        self.alignmentGuide(g, computeValue: computeValue)
    }
    
}
