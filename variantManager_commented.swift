// MARK: - Supporting Types
struct ValueAvailability: Hashable {
    let id = UUID() // Unique identifier for SwiftUI ForEach
    let value: String        // e.g., "مشکی", "XL" - the actual attribute value
    let totalStock: Int      // e.g., 12 (sum of stock for this value across all variants)
    let isAvailable: Bool    // e.g., true if totalStock > 0
}

// MARK: - Extensions
extension Array where Element == ProductTest.ProductAttribute {
    // Gets the value for a specific attribute key
    // Example: attributes.value(for: "رنگ") returns "مشکی"
    func value(for key: String) -> String? {
        first(where: { $0.key == key })?.value // Find first attribute with matching key, return its value
    }
}

// MARK: - Core Logic Functions
// Filters variants that match all current selections
// Example: selections = ["رنگ": "مشکی"] returns variants with color "مشکی"
func variantsMatching(_ variants: [ProductTest.Variant], selections: [String: String]) -> [ProductTest.Variant] {
    guard !selections.isEmpty else { return variants } // If no selections, return all variants
    return variants.filter { variant in // Filter variants that match ALL current selections
        selections.allSatisfy { k, v in // Check if ALL selections are satisfied
            variant.attributes.value(for: k) == v // Does this variant have the selected value for this key?
        }
    }
}

// Sums up stock quantities from multiple variants
// Example: [variant1(stock: 5), variant2(stock: 7)] returns 12
func totalStock(_ variants: [ProductTest.Variant]) -> Int {
    variants.reduce(0) { $0 + max(0, $1.stock_quantity) } // Sum all stock quantities, ignore negative values
}

// Discovers attribute keys in order from your data (no hardcoding)
// Example: returns ["رنگ", "سایز"] based on what's in your variants
func discoveredAttributeOrder(in variants: [ProductTest.Variant]) -> [String] {
    var order: [String] = [] // Array to store unique attribute keys in order
    var seen = Set<String>() // Set to track which keys we've already seen
    if let first = variants.first { // Start with first variant to establish order
        for a in first.attributes where !seen.contains(a.key) { // Add keys from first variant
            order.append(a.key); seen.insert(a.key) // Add to order and mark as seen
        }
    }
    for v in variants { // Go through all variants
        for a in v.attributes where !seen.contains(a.key) { // Add any new keys we haven't seen
            order.append(a.key); seen.insert(a.key) // Add to order and mark as seen
        }
    }
    return order // Return unique keys in discovery order
}

// Gets available options for a specific attribute key with their stock counts
// Example: key="سایز", selections=["رنگ": "مشکی"] returns [("M", 0), ("XL", 12)]
func availableValues(
    for key: String,
    in variants: [ProductTest.Variant],
    given selections: [String: String]
) -> [ValueAvailability] {
    
    var filteredSelections = selections // Copy selections to modify
    
    filteredSelections.removeValue(forKey: key) // Remove the key we're listing (ignore it in filtering)
    
    let base = variantsMatching(variants, selections: filteredSelections) // Get variants matching other selections

    var valueToVariants: [String: [ProductTest.Variant]] = [:] // Dictionary: value -> [variants with that value]
    for v in base { // For each matching variant
        if let value = v.attributes.value(for: key) { // Get the value for the key we're listing
            valueToVariants[value, default: []].append(v) // Group variants by this value
        }
    }

    return valueToVariants
        .map { value, group in // Convert each group to ValueAvailability
            let stock = totalStock(group) // Sum stock for all variants with this value
            return ValueAvailability(value: value, totalStock: stock, isAvailable: stock > 0) // Create availability object
        }
        .sorted { // Sort by availability, then stock, then alphabetically
            if $0.isAvailable != $1.isAvailable { return $0.isAvailable && !$1.isAvailable } // Available first
            if $0.totalStock != $1.totalStock { return $0.totalStock > $1.totalStock } // Higher stock first
            return $0.value < $1.value // Alphabetical order
        }
}

// Finds the exact variant when all attributes are selected
// Example: selections=["رنگ": "مشکی", "سایز": "XL"] returns variant 130
func resolvedVariant(from variants: [ProductTest.Variant], selections: [String: String]) -> ProductTest.Variant? {
    let matches = variantsMatching(variants, selections: selections) // Find variants matching all selections
    return matches.count == 1 ? matches.first : nil // Return variant only if exactly one match
}

// MARK: - SwiftUI View
struct VariantSelectorView: View {
    let product: ProductTest
    @State private var selections: [String: String] = [:] // Track user's current selections

    // Gets attribute order from your data (e.g., ["رنگ", "سایز"])
    private var attributeOrder: [String] {
        discoveredAttributeOrder(in: product.variants!) // Dynamically discover attribute keys
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Shows each attribute (color, size, etc.) as a section
            ForEach(attributeOrder, id: \.self) { key in // Loop through each attribute type
                let options = availableValues(for: key, in: product.variants!, given: selections) // Get available options for this attribute
                VStack(alignment: .leading, spacing: 8) {
                    Text(key).font(.headline) // Show attribute name (e.g., "رنگ" or "سایز")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Shows each option (e.g., "مشکی", "XL") with stock count
                            ForEach(options, id: \.id) { option in // Loop through each option
                                
                                let isSelected :Bool = selections[key] == option.value // Check if this option is selected
                                
                                Button {
                                    if isSelected { selections.removeValue(forKey: key) } // Deselect if already selected
                                    else {
                                        selections[key] = option.value // Select this option
                                        validateSelections() // Clean up invalid selections
                                    }
                                } label: {
                                    VStack {
                                        Text(option.value).font(.subheadline) // Show option value (e.g., "مشکی")
                                        Text("\(option.totalStock) در انبار") // Show stock count
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15)) // Highlight selected
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.4),
                                                    lineWidth: isSelected ? 2 : 1) // Border for selected
                                    )
                                }
                                .disabled(!option.isAvailable) // Disable when stock = 0
                                .opacity(option.isAvailable ? 1.0 : 0.4) // Fade out unavailable options
                            }
                        }
                    }
                }
            }

            // Shows the exact variant when fully selected
            if let v = resolvedVariant(from: product.variants!, selections: selections) { // If we have a unique match
                Text("شناسه: \(v.id) • موجودی: \(v.stock_quantity)") // Show variant details
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // Removes invalid selections when user changes choices
    // Example: if user changes color, removes size if that size+color combo doesn't exist
    private func validateSelections() {
        var valid = selections // Start with current selections
        for key in attributeOrder { // Check each attribute
            let options = availableValues(for: key, in: product.variants!, given: valid) // Get valid options
            if let selected = valid[key], // If we have a selection for this key
               options.first(where: { $0.value == selected && $0.isAvailable }) == nil { // And it's not available
                valid.removeValue(forKey: key) // Remove the invalid selection
            }
        }
        selections = valid // Update selections with cleaned up version
    }
    
    struct VariantInfoView: View {
        let product: ProductTest
        let selections: [String: String]
        
        var body: some View {
            if let v = resolvedVariant(from: product.variants!, selections: selections) { // Find matching variant
                Text("شناسه: \(v.id) • موجودی: \(v.stock_quantity)") // Show variant info
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VariantSelectorView(product: ProductTest.sampleProduct)
}
