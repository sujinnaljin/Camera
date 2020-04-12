//
//  ViewController.swift
//  Camera
//
//  Created by 강수진 on 2020/03/21.
//  Copyright © 2020 강수진. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let context = CIContext()

    @IBOutlet private weak var imageView: UIImageView!

    override func viewDidLoad() {
        CustomFiltersVendor.registerFilters()
        blurFace()
    }
    
    func customFilter() {
        let imageURL = URL(fileURLWithPath: "\(Bundle.main.bundlePath)/sujin.JPG")
        let inputImage = CIImage(contentsOf: imageURL)!
        if let newImage = inputImage.filtered(.removeHaze) {
            self.imageView.image = UIImage(ciImage: newImage)
        } else {
            print("없다")
        }
        

    }
    
  
    
    func blurFace() {
        let imageURL = URL(fileURLWithPath: "\(Bundle.main.bundlePath)/sujin.JPG")
        let inputImage = CIImage(contentsOf: imageURL)!
    
        guard let faceMaskCI = faceFilter(inputImage) else {
            return
        }
        
        guard let blurCI = blurFilter(inputImage, mask: faceMaskCI)?.cropped(to: inputImage.extent) else {
            return
        }
      
        
       // let rect = calOriginRect(blurred: blurCI, origin: inputImage)

        if let cgimg = context.createCGImage(blurCI, from: inputImage.extent) {
            self.imageView.image = UIImage(cgImage: cgimg)
        }
    }

    
    func calOriginRect(blurred: CIImage, origin: CIImage) -> CGRect{
        var rect = blurred.extent
        let originalImage = origin.extent
        rect.origin.x += (rect.size.width - originalImage.size.width) / 2
        rect.origin.y += (rect.size.height - originalImage.size.height) / 2
        rect.size = originalImage.size
        return rect
    }

    func faceFilter(_ image: CIImage) -> CIImage? {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil)
        let faceArray = detector?.features(in: image, options: nil)
        // Create a green circle to cover the rects that are returned.
        var maskImage: CIImage? = nil
        guard let faceArray_ = faceArray else {
            print("얼굴 없음")
            return nil
        }
        for f in faceArray_ {
            let centerX: CGFloat = f.bounds.origin.x + f.bounds.size.width / 2.0
            let centerY: CGFloat = f.bounds.origin.y + f.bounds.size.height / 2.0
            let radius: CGFloat = min(f.bounds.size.width, f.bounds.size.height) / 1.5
            let radialGradient = CIFilter(name: "CIRadialGradient", parameters: [
                "inputRadius0": NSNumber(value: Float(radius)),
                "inputRadius1": NSNumber(value: Float(radius + 1.0)),
                "inputColor0": CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.0),
                "inputColor1": CIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0),
                kCIInputCenterKey: CIVector(x: centerX, y: centerY)
            ])
            
            let circleImage = radialGradient?.outputImage
            if nil == maskImage {
                maskImage = circleImage
            } else {
                maskImage = CIFilter(name: "CISourceInCompositing", parameters: [
                    kCIInputImageKey: circleImage,
                    kCIInputBackgroundImageKey: maskImage
                    ])?.outputImage
            }
        }
        return maskImage
    }
    
    func findFirstFace(_ image : CIImage) -> (center: CIVector, height : CGFloat) {
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: nil) as? CIDetector
        let faceArray = detector?.features(in: image, options: nil)
        let face = faceArray?[0]
        let xCenter = (face?.bounds.origin.x ?? 0.0) + (face?.bounds.size.width ?? 0.0) / 2.0
        let yCenter = (face?.bounds.origin.y ?? 0.0) + (face?.bounds.size.height ?? 0.0) / 2.0
        let center = CIVector(x: xCenter, y: yCenter)
        let height = (face?.bounds.size.height ?? 0)
        return (center, height)
    }
    
    func blurFilter(_ inputImage : CIImage, mask: CIImage) -> CIImage? {
        let maskedVariableBlur = CIFilter(name: "CIMaskedVariableBlur")
        maskedVariableBlur?.setValue(inputImage, forKey: kCIInputImageKey)
        maskedVariableBlur?.setValue(20, forKey: kCIInputRadiusKey)
        maskedVariableBlur?.setValue(mask, forKey: "inputMask")
        return maskedVariableBlur?.outputImage
    }
      
    
    func radialGradientFilter(_ inputImage : CIImage, center: CIVector) -> CIImage? {
        let h = inputImage.extent.size.height
        let radialMask = CIFilter(name: "CIRadialGradient")
        radialMask?.setValue(center, forKey: kCIInputCenterKey)
        radialMask?.setValue(0.2 * h, forKey: "inputRadius0")
        radialMask?.setValue(0.3 * h, forKey: "inputRadius1")
        radialMask?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 0), forKey: "inputColor0")
        radialMask?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 1), forKey: "inputColor1")
        return radialMask?.outputImage
    }
    
    func gradientFilter(_ inputImage : CIImage) -> CIImage? {
        let h = inputImage.extent.size.height
        //topGradient
        let topGradient = CIFilter(name: "CILinearGradient")
        topGradient?.setValue(CIVector(x: 0, y: 0.85 * h), forKey: "inputPoint0")
        topGradient?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 1), forKey: "inputColor0")
        topGradient?.setValue(CIVector(x: 0, y: 0.6 * h), forKey: "inputPoint1")
        topGradient?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 0), forKey: "inputColor1")
        
        //bottomGradient
        let bottomGradient = CIFilter(name: "CILinearGradient")
        bottomGradient?.setValue(CIVector(x: 0, y: 0.35 * h), forKey: "inputPoint0")
        bottomGradient?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 1), forKey: "inputColor0")
        bottomGradient?.setValue(CIVector(x: 0, y: 0.6 * h), forKey: "inputPoint1")
        bottomGradient?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 0), forKey: "inputColor1")
        
        //gradientMask
        let gradientMask = CIFilter(name: "CIAdditionCompositing")
        guard let topGradient_ = topGradient, let bottomGradient_ = bottomGradient else {
            print("top botoom no")
            return nil
        }
        gradientMask?.setValue(topGradient_.outputImage, forKey: kCIInputImageKey)
        gradientMask?.setValue(bottomGradient_.outputImage, forKey: kCIInputBackgroundImageKey)
        return gradientMask?.outputImage
    }
    
    func blendFilter(_ input : CIImage, background : CIImage) -> CIImage? {
        let filter = CIFilter(name: "CISourceOverCompositing")
        filter?.setValue(input, forKey: "inputImage")
        filter?.setValue(background, forKey: "inputBackgroundImage")
        return filter?.outputImage
    }


    func sepiaFilter(_ input: CIImage, intensity: Double) -> CIImage?
    {
        let sepiaFilter = CIFilter(name:"CISepiaTone")
        sepiaFilter?.setValue(input, forKey: kCIInputImageKey)
        sepiaFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
        return sepiaFilter?.outputImage
    }
    

    func bloomFilter(_ input:CIImage, intensity: Double, radius: Double) -> CIImage?
    {
        let bloomFilter = CIFilter(name:"CIBloom")
        bloomFilter?.setValue(input, forKey: kCIInputImageKey)
        bloomFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
        bloomFilter?.setValue(radius, forKey: kCIInputRadiusKey)
        return bloomFilter?.outputImage
    }
    
    func scaleFilter(_ input:CIImage, aspectRatio : Double, scale : Double) -> CIImage
    {
        let scaleFilter = CIFilter(name:"CILanczosScaleTransform")!
        scaleFilter.setValue(input, forKey: kCIInputImageKey)
        scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
        scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        return scaleFilter.outputImage!
    }

}

