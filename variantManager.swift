//
//  variantManager.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 10/1/25.
//

import SwiftUI



// MARK: - Supporting Types
struct ValueAvailability: Hashable {
    let id = UUID() // Add this line
    let value: String        // e.g., "مشکی", "XL"
    let totalStock: Int      // e.g., 12 (sum of stock for this value)
    let isAvailable: Bool    // e.g., true if totalStock > 0
}

// MARK: - Extensions
extension Array where Element == ProductTest.ProductAttribute {
    // Gets the value for a specific attribute key
    // Example: attributes.value(for: "رنگ") returns "مشکی"
    // WITHOUT THIS: You'd have to manually search through arrays every time
    // - No easy way to get color from variant.attributes
    // - Would need: variant.attributes.first(where: { $0.key == "رنگ" })?.value
    // - Code becomes repetitive and error-prone
    func value(for key: String) -> String? {
        first(where: { $0.key == key })?.value
    }
}

// MARK: - Core Logic Functions
// Filters variants that match all current selections
// Example: selections = ["رنگ": "مشکی"] returns variants with color "مشکی"
// WITHOUT THIS: You'd see ALL variants regardless of user's color/size selection
// - User selects "مشکی" but still sees "سبز", "سفید", "قرمز" variants
// - No filtering based on user choices
// - UI shows irrelevant options
func variantsMatching(_ variants: [ProductTest.Variant], selections: [String: String]) -> [ProductTest.Variant] {
    guard !selections.isEmpty else { return variants }
    return variants.filter { variant in
        selections.allSatisfy { k, v in
            variant.attributes.value(for: k) == v
        }
    }
}

// Sums up stock quantities from multiple variants
// Example: [variant1(stock: 5), variant2(stock: 7)] returns 12
// WITHOUT THIS: You'd only see individual variant stock, not total available
// - Can't show "12 در انبار" for color "مشکی" (sum of all مشکی variants)
// - User doesn't know total availability across sizes
// - Bad user experience - shows "0 در انبار" even if other sizes have stock
func totalStock(_ variants: [ProductTest.Variant]) -> Int {
    variants.reduce(0) { $0 + max(0, $1.stock_quantity) }
}

// Discovers attribute keys in order from your data (no hardcoding)
// Example: returns ["رنگ", "سایز"] based on what's in your variants
// WITHOUT THIS: You'd have to hardcode attribute names
// - Code breaks if you add new attributes like "جنس", "brand"
// - UI doesn't automatically show new attribute types
// - Have to manually update ForEach loops every time
// - Not flexible for different product types
func discoveredAttributeOrder(in variants: [ProductTest.Variant]) -> [String] {
    var order: [String] = []
    var seen = Set<String>()
    if let first = variants.first {
        for a in first.attributes where !seen.contains(a.key) {
            order.append(a.key); seen.insert(a.key)
        }
    }
    for v in variants {
        for a in v.attributes where !seen.contains(a.key) {
            order.append(a.key); seen.insert(a.key)
        }
    }
    return order
}

// Gets available options for a specific attribute key with their stock counts
// Example: key="سایز", selections=["رنگ": "مشکی"] returns [("M", 0), ("XL", 12)]
// WITHOUT THIS: You'd show ALL possible sizes, even ones that don't exist for selected color
// - User selects "مشکی" but sees sizes "S", "M", "L", "XL" even if "S" doesn't exist in مشکی
// - Shows "0 در انبار" for non-existent combinations
// - User gets confused by unavailable options
// - No dynamic filtering based on other selections
func availableValues(
    for key: String,
    in variants: [ProductTest.Variant],
    given selections: [String: String]
) -> [ValueAvailability] {
    
    var filteredSelections = selections
    filteredSelections.removeValue(forKey: key) // ignore the key we're listing
    let base = variantsMatching(variants, selections: filteredSelections)

    var valueToVariants: [String: [ProductTest.Variant]] = [:]
    for v in base {
        if let value = v.attributes.value(for: key) {
            valueToVariants[value, default: []].append(v)
        }
    }

    return valueToVariants
        .map { value, group in
            let stock = totalStock(group)
            return ValueAvailability(value: value, totalStock: stock, isAvailable: stock > 0)
        }
        .sorted {
            if $0.isAvailable != $1.isAvailable { return $0.isAvailable && !$1.isAvailable }
            if $0.totalStock != $1.totalStock { return $0.totalStock > $1.totalStock }
            return $0.value < $1.value
        }
}

// Finds the exact variant when all attributes are selected
// Example: selections=["رنگ": "مشکی", "سایز": "XL"] returns variant 130
// WITHOUT THIS: You can't identify the specific variant user selected
// - Can't show exact variant ID, SKU, or individual stock
// - Can't add to cart because you don't know which variant
// - No way to get variant-specific price or details
// - User selects options but nothing happens
func resolvedVariant(from variants: [ProductTest.Variant], selections: [String: String]) -> ProductTest.Variant? {
    let matches = variantsMatching(variants, selections: selections)
    return matches.count == 1 ? matches.first : nil
}

// MARK: - SwiftUI View
struct VariantSelectorView: View {
    let product: ProductTest
    @State private var selections: [String: String] = [:]

    // Gets attribute order from your data (e.g., ["رنگ", "سایز"])
    private var attributeOrder: [String] {
        discoveredAttributeOrder(in: product.variants!)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Shows each attribute (color, size, etc.) as a section
            ForEach(attributeOrder, id: \.self) { key in
                let options = availableValues(for: key, in: product.variants!, given: selections)
                VStack(alignment: .leading, spacing: 8) {
                    Text(key).font(.headline) // e.g., "رنگ" or "سایز"
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Shows each option (e.g., "مشکی", "XL") with stock count
                            ForEach(options, id: \.id) { option in
                                
                                let isSelected :Bool = selections[key] == option.value
                                
                                Button {
                                    if isSelected { selections.removeValue(forKey: key) }
                                    else {
                                        selections[key] = option.value
                                        validateSelections()
                                    }
                                } label: {
                                    VStack {
                                        Text(option.value).font(.subheadline) // e.g., "مشکی"
                                        Text("\(option.totalStock) در انبار") // e.g., "12 در انبار"
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.4),
                                                    lineWidth: isSelected ? 2 : 1)
                                    )
                                }
                                .disabled(!option.isAvailable) // disabled when stock = 0
                                .opacity(option.isAvailable ? 1.0 : 0.4)
                            }
                        }
                    }
                }
            }

            // Shows the exact variant when fully selected
            
            if let v = resolvedVariant(from: product.variants!, selections: selections) {
                Text("شناسه: \(v.id) • موجودی: \(v.stock_quantity)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // Removes invalid selections when user changes choices
    // Example: if user changes color, removes size if that size+color combo doesn't exist
    // WITHOUT THIS: User can select invalid combinations
    // - Select "مشکی" + "S" even if that combination doesn't exist
    // - UI shows selected but no actual variant matches
    // - User gets confused when selections don't work
    // - No automatic cleanup of invalid choices
    private func validateSelections() {
        var valid = selections
        for key in attributeOrder {
            let options = availableValues(for: key, in: product.variants!, given: valid)
            if let selected = valid[key],
               options.first(where: { $0.value == selected && $0.isAvailable }) == nil {
                valid.removeValue(forKey: key)
            }
        }
        selections = valid
    }
    
    struct VariantInfoView: View {
        let product: ProductTest
        let selections: [String: String]
        
        var body: some View {
            if let v = resolvedVariant(from: product.variants!, selections: selections) {
                Text("شناسه: \(v.id) • موجودی: \(v.stock_quantity)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}



#Preview {
    VariantSelectorView(product: ProductTest.sampleProduct)
}
