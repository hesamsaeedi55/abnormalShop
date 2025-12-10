"""
🔥 SWIFT UI TAB INDICATOR FIX

The indicator doesn't work in fullscreen because:
1. Preference changes aren't propagating correctly
2. GeometryReader contexts are different
3. State updates aren't syncing between views

Here's the fixed version:
"""

// MARK: - FIXED VERSION

@ViewBuilder
func fullScreenImage() -> some View {
    GeometryReader { geometry in
        ZStack {
            // TabView with proper preference handling
            TabView(selection: $currentIndex) {
                ForEach(cachedImages.indices, id: \.self) { idx in
                    VStack {
                        Spacer()
                        Image(uiImage: cachedImages[idx])
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .onTapGesture {
                                // Remove this since we're already in fullscreen
                            }
                            .id("fullscreen-hero-\(idx)")
                            // Remove blur and offset that don't apply in fullscreen
                            .clipped()
                        Spacer()
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // 🔥 FIX: Add preference change handler here
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .global).minX)
                }
            )
            .onPreferenceChange(ScrollOffsetKey.self) { newOffset in
                // 🔥 FIX: Update drag progress in fullscreen context
                updateDragProgressFullscreen(newOffset, screenWidth: geometry.size.width)
            }
            
            // Close button overlay
            VStack {
                HStack {
                    Button {
                        withAnimation(.easeOut) {
                            isFullScreen = false
                        }
                    } label: {
                        Image(systemName:"xmark.circle.fill")
                            .resizable()
                            .frame(width: geometry.size.width/18, height: geometry.size.width/18)
                            .foregroundStyle(.white)
                            .opacity(0.80)
                    }
                    .padding(.leading, 20)
                    .padding(.top, height/20)
                    Spacer()
                }

                Spacer()
                
                // 🔥 FIX: Properly positioned indicator for fullscreen
                imageTabIndicatorFullscreen()
                    .padding(.bottom, 50)
            }
        }
    }
    .background(.black)
    .ignoresSafeArea()
}

// 🔥 NEW: Separate indicator for fullscreen mode
@ViewBuilder
private func imageTabIndicatorFullscreen() -> some View {
    HStack {
        VStack(alignment: .leading, spacing: height/100) {
            HStack {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ForEach(Array(product.images.enumerated()), id: \.element.id) { (idx, image) in
                            Rectangle()
                                .fill(Color.white) // White for fullscreen
                                .frame(width: getDynamicWidthFullscreen(for: idx), height: 3)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentIndex = idx
                                    }
                                }
                        }
                        Spacer()
                    }
                    .frame(width: 400, height: height / 36)
                }
            }
        }
        .padding(.leading, width/50)
        Spacer()
    }
    .frame(width: width)
}

// 🔥 NEW: Separate drag progress update for fullscreen
private func updateDragProgressFullscreen(_ newOffset: CGFloat, screenWidth: CGFloat) {
    let progress = newOffset.truncatingRemainder(dividingBy: screenWidth) / screenWidth
    dragProgress = abs(min(max(0, 1-progress), 1+progress))
    
    let isNowSwipingRight = newOffset > 0
    let isNowSwipingLeft = newOffset < 0
    
    if isNowSwipingRight {
        lastSwipeDirection = .right
    } else if isNowSwipingLeft {
        lastSwipeDirection = .left
    }
}

// 🔥 NEW: Separate width calculation for fullscreen
private func getDynamicWidthFullscreen(for index: Int) -> CGFloat {
    let baseWidth = width / 25  // Slightly larger for visibility
    let expandedWidth = width / 5
    let nextIndex = currentIndex + 1
    let previousIndex = currentIndex - 1

    // Simplified logic for fullscreen
    switch lastSwipeDirection {
    case .right:
        if index == currentIndex {
            return dragProgress < 0.5 ? expandedWidth - (expandedWidth * dragProgress) : expandedWidth
        } else if index == nextIndex {
            return dragProgress < 0.5 ? baseWidth + (expandedWidth * dragProgress) : baseWidth
        } else {
            return baseWidth
        }

    case .left:
        if index == currentIndex {
            return dragProgress < 0.5 ? expandedWidth - (expandedWidth * dragProgress) : expandedWidth
        } else if index == previousIndex {
            return dragProgress < 0.5 ? baseWidth + (expandedWidth * dragProgress) : baseWidth
        } else {
            return baseWidth
        }

    case .none:
        return index == currentIndex ? expandedWidth : baseWidth
    }
}

// 🔥 ALTERNATIVE: Simple indicator that always works
@ViewBuilder
private func simpleTabIndicatorFullscreen() -> some View {
    HStack(spacing: 8) {
        ForEach(Array(product.images.enumerated()), id: \.element.id) { (idx, image) in
            Circle()
                .fill(Color.white.opacity(idx == currentIndex ? 1.0 : 0.5))
                .frame(width: idx == currentIndex ? 12 : 8, height: idx == currentIndex ? 12 : 8)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentIndex = idx
                    }
                }
        }
    }
    .padding(.bottom, 50)
}

// 🔥 MAIN ISSUE FIXES:

/*
PROBLEMS IDENTIFIED:

1. ❌ Preference changes not working in fullscreen context
2. ❌ GeometryReader frame calculations different in fullscreen
3. ❌ State updates not syncing between normal and fullscreen views
4. ❌ Complex width calculations causing glitches
5. ❌ Color inversion making indicators invisible

SOLUTIONS APPLIED:

1. ✅ Separate preference handler for fullscreen context
2. ✅ Simplified width calculations for fullscreen
3. ✅ Proper state management between views
4. ✅ White indicators for black background
5. ✅ Alternative simple circle indicators as backup

KEY CHANGES:

1. Separate `imageTabIndicatorFullscreen()` function
2. Separate `updateDragProgressFullscreen()` function  
3. Separate `getDynamicWidthFullscreen()` function
4. Proper preference change handling in fullscreen TabView
5. White indicators instead of color inversion

QUICK FIX - Replace your fullscreen indicator call:

// Instead of:
imageTabIndicator().colorInvert()

// Use:
imageTabIndicatorFullscreen()

// Or for simple solution:
simpleTabIndicatorFullscreen()
*/

// 🔥 DEBUGGING: Add this to see what's happening
private func debugTabIndicator() -> some View {
    VStack {
        Text("Current Index: \(currentIndex)")
        Text("Drag Progress: \(String(format: "%.2f", dragProgress))")
        Text("Swipe Direction: \(String(describing: lastSwipeDirection))")
        Text("Is Full Screen: \(isFullScreen)")
    }
    .foregroundColor(.white)
    .padding()
    .background(Color.black.opacity(0.7))
    .cornerRadius(10)
}

// Add this to your fullscreen view to debug:
// debugTabIndicator()
