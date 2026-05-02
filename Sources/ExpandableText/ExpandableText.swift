// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// Adds expandable and collapsible behavior to any view displaying text content.
///
/// This modifier truncates the content to a specified number of lines and optionally
/// reveals the full content with an animated transition. When truncated, a customizable
/// trailing text (for example, “…More”) is displayed.
///
/// - Parameters:
///   - length: The maximum number of lines to display when collapsed.
///   - isEnabled: A Boolean value that controls whether the expandable behavior is active.
///                When `false`, the content is fully expanded.
///   - moreText: A string displayed at the end of truncated content.
///               Defaults to `"...More"`.
///   - blurRadius: The blur radius applied to truncated lines during transition.
///                 Set to `0` to disable blur.
///   - animation: The animation used when transitioning between collapsed and expanded states.
///
/// - Returns: A view that conditionally truncates and expands its content.
///
/// - Note:
/// This API requires iOS 18 or later due to reliance on advanced text rendering APIs.
@available(iOS 18, *)
extension View {
    @ViewBuilder
    public func expandable(
        length: Int,
        isEnabled: Bool,
        moreText: String = "...More",
        blurRadius: CGFloat = 2,
        animation: Animation
    ) -> some View {
        self
            .modifier(
                ExpandableTextModifier(
                    length: length,
                    isEnabled: isEnabled,
                    moreText: moreText,
                    blurRadius: blurRadius,
                    animation: animation
                )
            )
    }
}

/// Conditionally clips the view based on the provided blur radius.
///
/// - Parameter blurRadius: The blur radius applied to the content.
/// - Returns: A clipped view when `blurRadius` is `0`, otherwise the original view.
///
/// - Discussion:
/// Clipping ensures that overflowing content is constrained when no blur effect is applied.
/// When blur is enabled, clipping is avoided to preserve the visual fade effect.
@available(iOS 18, *)
extension View {
    @ViewBuilder
    fileprivate func optionalClip(blurRadius: CGFloat)-> some View {
        if blurRadius.isZero {
            self
                .clipped()
        }else {
            self
        }
    }
}


/// A view modifier that provides expandable text behavior with animated truncation.
///
/// This modifier measures both truncated and full content sizes and transitions
/// between them using a custom animation and renderer.
///
/// - Important:
/// This modifier relies on geometry measurement and custom text rendering,
/// which may have performance implications for very large text bodies.
@available(iOS 18, *)
fileprivate struct ExpandableTextModifier: ViewModifier {
    var length: Int
    var isEnabled: Bool
    var moreText: String
    var blurRadius: CGFloat
    var animation: Animation
    
    @State private var limitedSize: CGSize = .zero
    @State private var fullSize: CGSize = .zero
    @State private var animatedProgress: CGFloat = .zero
    func body(content: Content) -> some View {
        content
            .lineLimit(length)
            .opacity(0)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { newValue in
                limitedSize = newValue
            }
            .frame(height: isExpanded ? fullSize.height : nil)
            .overlay {
                GeometryReader {
                    let contentSize = $0.size
                    content
                        .textRenderer(
                            TruncationTextRenderer(
                                length: length,
                                moreText: moreText,
                                blurRadius: blurRadius,
                                progress: animatedProgress
                            )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            fullSize = newValue
                        }
                        .frame(
                            width: contentSize.width,
                            height: contentSize.height,
                            alignment: isExpanded ? .leading : .topLeading
                        )
                }
            }
            .optionalClip(blurRadius: blurRadius)
            .contentShape(.rect)
            .onChange(of: isEnabled) { oldValue, newValue in
                withAnimation(animation) {
                    animatedProgress = !newValue ? 1 : 0
                }
            }
            .onAppear {
                animatedProgress = !isEnabled ? 1 : 0
            }
        
    }
    
    var isExpanded: Bool {
        animatedProgress == 1
    }
    
}

/// A custom text renderer that handles truncation, blur transitions,
/// and rendering of trailing “more” text.
///
/// This renderer provides fine-grained control over individual text lines,
/// enabling progressive reveal and visual effects during expansion.
///
/// - Note:
/// Uses SwiftUI’s `TextRenderer` API introduced in iOS 18.
@available(iOS 18, *)
@Animatable
fileprivate struct TruncationTextRenderer: TextRenderer {
    @AnimatableIgnored var length: Int
    @AnimatableIgnored var moreText: String
    var blurRadius: CGFloat
    var progress: CGFloat
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        for (index, line) in layout.enumerated() {
            var copyContext = ctx
            if (index == length - 1){
                drawMoreTextAtEnd(line: line, context: &copyContext)
            }else {
                if index < length  || blurRadius.isZero{
                    copyContext.draw(line)
                }else {
                    drawLinesWithBlurEffect(index: index, layout: layout, context: &copyContext)
                }
            }
        }
    }
    
    /// Applies a progressive blur and opacity effect to lines beyond the truncation limit.
    ///
    /// - Parameters:
    ///   - index: The current line index.
    ///   - layout: The full text layout.
    ///   - context: The graphics context used for rendering.
    ///
    /// - Discussion:
    /// Each line fades in and sharpens as `progress` approaches 1,
    /// creating a smooth expansion animation.
    func drawLinesWithBlurEffect(index: Int, layout: Text.Layout, context: inout GraphicsContext){
        let line = layout[index]
        let lineIndex = Double(index - length)
        let totalExtraLines = Double(layout.count - length)
        
        let lineStartProgress = lineIndex / max(1, totalExtraLines)
        let lineEndProgress = (lineIndex + 1) / max(1, totalExtraLines)
        
        let lineProgress = max(0, min(1, (progress - lineStartProgress) / (lineEndProgress - lineStartProgress)))
        context.opacity = lineProgress
        context.addFilter(.blur(radius: blurRadius - (blurRadius * lineProgress)))
        context.draw(line)
    }
    
    /// Draws the trailing “more” text at the end of the last visible line.
    ///
    /// - Parameters:
    ///   - line: The last visible line.
    ///   - context: The graphics context used for rendering.
    ///
    /// - Discussion:
    /// This method replaces the end of the last visible line with
    /// a partially faded original text and overlays the `moreText`.
    ///
    /// The transition is animated using `progress`, blending between
    /// truncated and full states.
    func drawMoreTextAtEnd(line: Text.Layout.Element, context: inout GraphicsContext){
        let runs = line.flatMap { $0 }
        let runsCount = runs.count
        let textCount = moreText.count
        
        for index in 0..<max(runsCount - textCount, 0){
            let run = runs[index]
            context.draw(run)
        }
        
        for index in max(runsCount - textCount, 0)..<runsCount {
            let run = runs[index]
            context.opacity = progress
            context.draw(run)
        }
        
        let textRunIndex = max(runsCount - textCount, 0)
        guard !runs.isEmpty else { return }
        let run = runs[textRunIndex]
        let typography = run.typographicBounds
        let fontSize: CGFloat = typography.ascent
        let font: UIFont = UIFont.systemFont(ofSize: fontSize)
        let spacing: CGFloat = NSString(string: moreText).size(withAttributes: [
            .font: font
        ]).width / 2
        let swiftUIText = Text(moreText)
            .font(Font(font))
            .foregroundStyle(.gray)
        let origin = CGPoint(
            x: typography.rect.minX + spacing,
            y: typography.rect.midY
        )
        context.opacity = 1 - progress
        context.draw(swiftUIText, at: origin )
    }
    
}

