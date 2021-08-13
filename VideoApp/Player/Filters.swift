//
//  Filters.swift
//  VideoApp
//
//  Created by Duy Truong on 14/07/2021.
//

import UIKit

let CIFilterNames = [
    "CISharpenLuminance",
    "CIPhotoEffectChrome",
    "CIPhotoEffectFade",
    "CIPhotoEffectInstant",
    "CIPhotoEffectNoir",
    "CIPhotoEffectProcess",
    "CIPhotoEffectTonal",
    "CIPhotoEffectTransfer",
    "CISepiaTone",
    "CIColorClamp",
    "CIColorInvert",
    "CIColorMonochrome",
    "CISpotLight",
    "CIColorPosterize",
    "CIBoxBlur",
    "CIDiscBlur",
    "CIGaussianBlur",
    "CIMaskedVariableBlur",
    "CIMedianFilter",
    "CIMotionBlur",
    "CINoiseReduction"
]

let filterNames = ["Luminance","Chrome","Fade","Instant","Noir","Process","Tonal","Transfer","SepiaTone","ColorClamp","ColorInvert","ColorMonochrome","SpotLight","ColorPosterize","BoxBlur","DiscBlur","GaussianBlur","MaskedVariableBlur","MedianFilter","MotionBlur","NoiseReduction"]

extension UIImage {
    
    func addFilter(_ filter: String) -> UIImage {
        guard let ciImage = CIImage(image: self) else { return self }
        
        let filterdCIImage = ciImage.applyingFilter(filter)
        if let cgImage = CIContext(options: nil).createCGImage(filterdCIImage, from: filterdCIImage.extent) {
            return UIImage(cgImage: cgImage)
        } else {
            return UIImage(ciImage: filterdCIImage, scale: 1.0, orientation: .up)
        }
    }
    
}
