//
//  LaMaOutput.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import CoreML

public final
class LaMaOutput: MLFeatureProvider
{
    // MARK: - Properties -
    
    private
    let provider: MLFeatureProvider
    
    public
    var output: CVPixelBuffer? {
        
        self.provider.featureValue(for: "output")?.imageBufferValue
    }
    
    public
    var featureNames: Set<String> {
        
        self.provider.featureNames
    }
    
    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    init(provider: MLFeatureProvider)
    {
        self.provider = provider
    }
    
    public
    func featureValue(for featureName: String) -> MLFeatureValue?
    {
        self.provider.featureValue(for: featureName)
    }
}
