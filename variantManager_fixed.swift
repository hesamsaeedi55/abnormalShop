//
//  variantManager.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 10/1/25.
//

import SwiftUI

struct VariantSelectorView: View {
    
    var product: ProductTest
    @State var selectedColor = ""
    @State var colorSet : [String] = []
    var body: some View {
        VStack {
            
            
            
            HStack {
                
                let uniqueColors = Set(product.variants!.compactMap({ variant in
                    
                    variant.attributes.first(where: { $0.isDistinctive})?.value
                    
                })).sorted()
                
                
                ForEach(Array(uniqueColors),id:\.self) { variant in
                    
                    Button {
                        
                        selectedColor = variant
                        
                        
                    }label: {
                        
                        Text(variant)
                            .opacity(selectedColor == variant ? 1 : 0.2)
                            .foregroundStyle(.black)
                        
                            }
                        }
               
                    }
            
            HStack {
                
                let uniqueSizes = Set(product.variants!.compactMap({ variant in
                    variant.attributes.first(where: { $0.isDistinctive == false })?.value
                })).sorted()
                
                // Create a mapping of size to its color for the selected color
                let sizeToColorMap = product.variants!.reduce(into: [String: String]()) { result, variant in
                    let color = variant.attributes.first(where: { $0.isDistinctive == true })?.value
                    let size = variant.attributes.first(where: { $0.isDistinctive == false })?.value
                    
                    if let color = color, let size = size {
                        result[size] = color
                    }
                }
                
                VStack {
                  
                    HStack {
                        
                        ForEach(uniqueSizes.indices, id: \.self) { index in
                            
                            let size = uniqueSizes[index]
                            let sizeColor = sizeToColorMap[size]
                            
                            HStack {
                                Text(size)
                                    .opacity(sizeColor == selectedColor ? 1 : 0.2)
                            } .padding().background(.orange)
                        }
                    }
                }
            }
        }.onAppear {
            isDefaultAssigning()
        }
    }
    
        func isDefaultAssigning() {
            
            if let defaultVariant = product.variants!.first(where:{$0.is_default}) {
                
                let distinctiveAttribute = defaultVariant.attributes.first(where:{ $0.isDistinctive })?.value
                
                selectedColor = distinctiveAttribute!
                
            }
        }




}

struct Variant:Codable,Identifiable,Hashable {
    
    let id: Int
    let sku: String
    let attributes:[ProductAttribute]
    let price_toman: Double?
    let stock_quantity: Int
    let is_active:Bool
    let images:[VariantImage]
    let is_default:Bool
    let isDistinctive: Bool

   
    
    struct VariantImage: Codable,Identifiable,Hashable {
        let id: Int
        let url: String
        let isPrimary: Bool
        let order: Int?
        
        enum CodingKeys: String, CodingKey {
            case id
            case url
            case isPrimary = "is_primary"
            case order
        }
    }
    
}

struct ProductImage: Codable,Identifiable {
    let id = UUID()
    let url: String
    let isPrimary: Bool
    
    enum CodingKeys: String, CodingKey {
        case url
        case isPrimary = "is_primary"
    }
}

struct ProductAttribute: Codable,Hashable {
    let key: String
    let value: String
    let isDistinctive: Bool
}

struct ProductTest: Codable {
    let id: Int?
    let name: String
    let variants: [Variant]?
    
    static let sampleProduct = ProductTest(
        id: 1,
        name: "Sample Product",
        variants: [
            Variant(
                id: 1,
                sku: "SKU-001",
                attributes: [
                    ProductAttribute(key: "color", value: "Red", isDistinctive: true),
                    ProductAttribute(key: "size", value: "M", isDistinctive: false)
                ],
                price_toman: 100.0,
                stock_quantity: 10,
                is_active: true,
                images: [],
                is_default: true,
                isDistinctive: true
            )
        ]
    )
}

#Preview {
    VariantSelectorView(product: ProductTest.sampleProduct)
}