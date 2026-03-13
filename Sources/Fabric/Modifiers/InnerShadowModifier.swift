import SwiftUI

extension View {
    /// Apply an inner shadow clipped to the given shape.
    ///
    /// Works by stroking the shape edge with a transparent color, applying a
    /// drop shadow to that stroke, then clipping so only the inward portion
    /// of the shadow is visible. Avoids expensive blur() + mask() stacking.
    public func innerShadow<S: Shape>(
        _ shape: S,
        color: Color = FabricColors.innerShadow,
        radius: CGFloat = 2,
        spread: CGFloat = 3,
        x: CGFloat = 0,
        y: CGFloat = 1
    ) -> some View {
        self
            .overlay(
                shape
                    .stroke(Color.clear, lineWidth: spread * 2)
                    .shadow(color: color, radius: radius, x: x, y: y)
            )
            .clipShape(shape)
    }
}
