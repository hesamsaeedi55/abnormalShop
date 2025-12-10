// MARK: - Supporting Types
struct ValueAvailability: Hashable, Identifiable {
    let id = UUID()
    let value: String        // e.g., "مشکی", "XL"
    let totalStock: Int      // e.g., 12 (sum of stock for this value)
    let isAvailable: Bool    // e.g., true if totalStock > 0
}

// MARK: - Extensions
extension Array where Element == ProductTest.ProductAttribute {
    // Gets the value for a specific attribute key
    // Example: attributes.value(for: "رنگ") returns "مشکی"
    func value(for key: String) -> String? {
        first(where: { $0.key == key })?.value
    }
}

// MARK: - Core Logic Functions
// Filters variants that match all current selections
// Example: selections = ["رنگ": "مشکی"] returns variants with color "مشکی"
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
func totalStock(_ variants: [ProductTest.Variant]) -> Int {
    variants.reduce(0) { $0 + max(0, $1.stock_quantity) }
}

// Discovers attribute keys in order from your data (no hardcoding)
// Example: returns ["رنگ", "سایز"] based on what's in your variants
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
func resolvedVariant(from variants: [ProductTest.Variant], selections: [String: String]) -> ProductTest.Variant? {
    let matches = variantsMatching(variants, selections: selections)
    return matches.count == 1 ? matches.first : nil
}

// MARK: - SwiftUI Views

// Separate view for each attribute section to avoid compiler type-checking issues
struct AttributeSectionView: View {
    let key: String
    let product: ProductTest
    @Binding var selections: [String: String]
    let onValidate: () -> Void
    
    private var options: [ValueAvailability] {
        availableValues(for: key, in: product.variants!, given: selections)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(key)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.id) { option in
                        OptionButtonView(
                            option: option,
                            key: key,
                            selections: $selections,
                            onValidate: onValidate
                        )
                    }
                }
            }
        }
    }
}

// Separate view for each option button to simplify type checking
struct OptionButtonView: View {
    let option: ValueAvailability
    let key: String
    @Binding var selections: [String: String]
    let onValidate: () -> Void
    
    private var isSelected: Bool {
        selections[key] == option.value
    }
    
    var body: some View {
        Button {
            if isSelected {
                selections.removeValue(forKey: key)
            } else {
                selections[key] = option.value
                onValidate()
            }
        } label: {
            VStack {
                Text(option.value)
                    .font(.subheadline)
                Text("\(option.totalStock) در انبار")
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
        .disabled(!option.isAvailable)
        .opacity(option.isAvailable ? 1.0 : 0.4)
    }
}

// Main variant selector view
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
                AttributeSectionView(
                    key: key,
                    product: product,
                    selections: $selections,
                    onValidate: validateSelections
                )
            }

            // Shows the exact variant when fully selected
            if let v = resolvedVariant(from: product.variants, selections: selections) {
                Text("شناسه: \(v.id) • موجودی: \(v.stock_quantity)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // Removes invalid selections when user changes choices
    // Example: if user changes color, removes size if that size+color combo doesn't exist
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
}
