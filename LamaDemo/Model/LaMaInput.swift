//
//  LaMaInput.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import CoreML
import UIKit

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
        guard let imageCGImage = image.cgImage,
              let maskCGImage = mask.cgImage else {
            
            throw NSError(domain: "LaMaInputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image or mask"])
        }
        
        // 建立圖片的 pixel buffer - 使用 RGB 格式
        let imageFeatureValue = try MLFeatureValue(cgImage: imageCGImage,
                                                   pixelsWide: Int(image.size.width),
                                                   pixelsHigh: Int(image.size.height),
                                                   pixelFormatType: kCVPixelFormatType_32BGRA,
                                                   options: nil)
        
        guard let imagePixelBuffer = imageFeatureValue.imageBufferValue else {
            
            throw NSError(domain: "LaMaInputError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create image pixel buffer"])
        }
        
        // 建立遮罩的 pixel buffer - 使用灰階格式
        let maskFeatureValue = try MLFeatureValue(cgImage: maskCGImage,
                                                  pixelsWide: Int(mask.size.width),
                                                  pixelsHigh: Int(mask.size.height),
                                                  pixelFormatType: kCVPixelFormatType_OneComponent8,
                                                  options: nil)
        
        guard let maskPixelBuffer = maskFeatureValue.imageBufferValue else {
            
            throw NSError(domain: "LaMaInputError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create mask pixel buffer"])
        }
        
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
