//
//  CustomFilter.swift
//  Camera
//
//  Created by 강수진 on 2020/03/25.
//  Copyright © 2020 강수진. All rights reserved.
//

import Foundation
import CoreImage
//https://www.bignerdranch.com/blog/custom-filters-with-core-image-kernel-language/ 참고

class HazeRemoveFilter: CIFilter {
    @objc dynamic var inputImage: CIImage?
    @objc dynamic var inputColor: CIColor = CIColor.white
    @objc dynamic var inputDistance: NSNumber = 0.2
    @objc dynamic var inputSlope: NSNumber = 0
    override var attributes: [String : Any] {
        return [
            kCIAttributeFilterDisplayName: "Remove Haze",
            
            "inputImage": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "CIImage",
                           kCIAttributeDisplayName: "Image",
                           kCIAttributeType: kCIAttributeTypeImage],
            
            "inputDistance": [kCIAttributeIdentity: 0,
                              kCIAttributeClass: "NSNumber",
                              kCIAttributeDisplayName: "Distance Factor",
                              kCIAttributeDefault: 0.2,
                              kCIAttributeMin: 0,
                              kCIAttributeMax: 1,
                              kCIAttributeSliderMin: 0,
                              kCIAttributeSliderMax: 0.7,
                              kCIAttributeType: kCIAttributeTypeScalar],
            "inputSlope": [kCIAttributeIdentity: 0,
                           kCIAttributeClass: "NSNumber",
                           kCIAttributeDisplayName: "Slope Factor",
                           kCIAttributeDefault: 0.2,
                           kCIAttributeSliderMin: -0.01,
                           kCIAttributeSliderMax: 0.01,
                           kCIAttributeType: kCIAttributeTypeScalar],
            kCIInputColorKey: [
                kCIAttributeDefault: CIColor.white
            ]
        ]
    }
    
    private lazy var hazeRemovalKernel: CIColorKernel? = {
      guard let path = Bundle.main.path(forResource: "HazeRemove", ofType: "cikernel"),
        let code = try? String(contentsOfFile: path) else { fatalError("Failed to load HazeRemove.cikernel from bundle") }
        let kernel = CIColorKernel(source: code)
      return kernel
    }()
    
    override var outputImage: CIImage? {
      get {
        if let inputImage = self.inputImage {
          return hazeRemovalKernel?.apply(extent: inputImage.extent, arguments: [
            inputImage as Any,
            inputColor,
            inputDistance,
            inputSlope
          ])
        } else {
          return nil
        }
      }
    }
    
}



class CustomFiltersVendor: NSObject, CIFilterConstructor {
    public static let HazeRemoveFilterName = "HazeRemoveFilter"

    static func registerFilters() {
        let classAttributes = [kCIAttributeFilterCategories: ["CustomFilters"]]
        HazeRemoveFilter.registerName(HazeRemoveFilterName, constructor: CustomFiltersVendor(), classAttributes: classAttributes)
    }
    
    func filter(withName name: String) -> CIFilter? {
      switch name
      {
        case CustomFiltersVendor.HazeRemoveFilterName:
          return HazeRemoveFilter()
        default:
          return nil
      }
    }
}

extension CIImage {
    enum Filter {
        case none
        case removeHaze
    }
    
    func filtered(_ filter: Filter)  -> CIImage? {
        let parameters: [String: AnyObject]
        let filterName: String
        let shouldCrop: Bool
        // Configure the CIFilter() inputs based on the chosen filter
        switch filter {
        case .none:
            return self
        case .removeHaze:
            parameters = [
                kCIInputImageKey: self
            ]
            filterName = CustomFiltersVendor.HazeRemoveFilterName
            shouldCrop = false
            
            guard let filter = CIFilter(name: filterName, parameters: parameters),
                let output = filter.outputImage else {
                    return nil
                    //throw ImageProcessor.Error.filterConfiguration(name: filterName, params: parameters)
            }
            
            // Crop back to the extent if necessary
            if shouldCrop {
                let croppedImage = output.cropped(to: extent)
                return croppedImage
            } else {
                return output
            }
        }
    }
}


