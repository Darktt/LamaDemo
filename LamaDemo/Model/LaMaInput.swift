//
//  LaMaInput.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import CoreML
import UIKit.UIImage

public final
class LaMaInput: MLFeatureProvider
{
    // MARK: - Properties -
    
    public
    let image: CVPixelBuffer
    
    public
    let mask: CVPixelBuffer
    
    public
    var featureNames: Set<String> { ["image", "mask"] }
    
    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    init(image: CVPixelBuffer, mask: CVPixelBuffer)
    {
        self.image = image
        self.mask = mask
    }
    
    public convenience
    init(image: UIImage, mask: UIImage) throws
    {
        guard let image = image.cgImage, let mask = mask.cgImage else {
            
            throw NSError(domain: "LaMaInputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image or mask"])
        }
        
        var featureValue = try MLFeatureValue(cgImage: image, pixelsWide: 800, pixelsHigh: 800, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil)
        let imagePixelBuffer = featureValue.imageBufferValue!
        
        featureValue = try MLFeatureValue(cgImage: mask, pixelsWide: 800, pixelsHigh: 800, pixelFormatType: kCVPixelFormatType_32ARGB, options: nil)
        let maskPixelBuffer = featureValue.imageBufferValue!
        
        self.init(image: imagePixelBuffer, mask: maskPixelBuffer)
    }
    
    public
    func featureValue(for featureName: String) -> MLFeatureValue?
    {
        var pixelBuffer: CVPixelBuffer? = nil
        
        if featureName == "image" {
            
            pixelBuffer = self.image
        }
        
        if featureName == "mask" {
            
            pixelBuffer = self.mask
        }
        
        let featureValue = pixelBuffer.map { MLFeatureValue(pixelBuffer: $0) }
        
        return featureValue
    }
}
