//
//  LaMa.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import CoreML

public final
class LaMa
{
    // MARK: - Properties -
    
    private
    var model: MLModel
    
    // MARK: - Initial Method -
    
    public
    init(contentsOf modelURL: URL) throws
    {
        let model = try MLModel(contentsOf: modelURL)
        
        self.model = model
    }
    
    public
    func prediction(input: LaMaInput, options: MLPredictionOptions) throws -> LaMaOutput
    {
        let outFeatures: MLFeatureProvider = try self.model.prediction(from: input, options: options)
        let output = LaMaOutput(provider: outFeatures)
        
        return output
    }
}
