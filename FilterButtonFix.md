# Quick Fix for Filter Button Crash

## The Problem
When you tap the filter button (فیلتر), two things happen simultaneously:
1. `isMainTabBarPresented = false` (hides tab bar)  
2. `searchForSearchToggle = true` (shows search overlay)

This creates a layout conflict causing the crash.

## Simple Fix Option 1: Add Delay
Replace your filter button action with this:

```swift
Button {
    // Hide tab bar first
    isMainTabBarPresented = false
    
    // Then show search view after a small delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        searchForSearchToggle = true
    }
    
} label: {
    Image("filter")
        .resizable()
        .frame(width:20,height:20)
        .foregroundStyle(.black)
}
```

## Better Fix Option 2: Async Sequence
```swift
Button {
    Task { @MainActor in
        // 1. Hide tab bar with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isMainTabBarPresented = false
        }
        
        // 2. Wait for animation to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // 3. Then show search view
        searchForSearchToggle = true
    }
} label: {
    Image("filter")
        .resizable()
        .frame(width:20,height:20)
        .foregroundStyle(.black)
}
```

## Best Fix Option 3: Use Sheet Instead
Replace your search overlay with a sheet:

```swift
// Remove the search overlay from your ZStack and add this instead:
.sheet(isPresented: $searchForSearchToggle, onDismiss: {
    // Show tab bar when search is dismissed
    withAnimation(.easeInOut(duration: 0.3)) {
        isMainTabBarPresented = true
    }
}) {
    SearchView(viewModel: AttributeViewModel(categoryID: viewModel.categoryId!), isPresented: $searchForSearchToggle)
}
```

Try **Option 1** first - it's the simplest and should fix your crash! 