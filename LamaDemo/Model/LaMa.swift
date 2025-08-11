//
//  LaMa.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

@preconcurrency
import CoreML

public final
class LaMa: @unchecked Sendable
{
    // MARK: - Properties -
    
    private
    var model: MLModel
    
    private
    lazy var dispatchQueue: DispatchQueue = {
        
        DispatchQueue(label: "com.darktt.lama.model.queue", qos: .userInitiated)
    }()
    
    // MARK: - Initial Method -
    
    public
    init(contentsOf modelURL: URL) throws
    {
        let model = try MLModel(contentsOf: modelURL)
        
        self.model = model
    }
    
    public
    func prediction(input: LaMaInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> LaMaOutput
    {
        let output = try await withCheckedThrowingContinuation {
            
            continuation in
            
            self.dispatchQueue.async {
                
                do {
                    let outFeatures: MLFeatureProvider = try self.model.prediction(from: input, options: options)
                    let output = LaMaOutput(provider: outFeatures)
                    
                    continuation.resume(returning: output)
                } catch {
                    
                    continuation.resume(throwing: error)
                }
            }
        }
        
        return output
    }
}
