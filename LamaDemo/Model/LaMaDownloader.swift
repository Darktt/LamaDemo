//
//  LaMaDownloader.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import Foundation

private
let modelURL = "https://github.com/Darktt/LamaDemo/blob/model/model/LaMa.zip"

private
typealias DownloadResult = (location: URL, response: URLResponse)

public final
class LaMaDownloader
{
    // MARK: - Properties -
    
    private
    lazy var session = {
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        
        let session = URLSession(configuration: configuration)
        
        return session
    }()
    
    // MARK: - Methods -
    // MARK: Initial Method
    
    public static
    func donloadModel() async throws -> LaMa
    {
        try await LaMaDownloader().downloadModel()
    }
    
    private
    init() { }
}

// MARK: - Private Methods -

private
extension LaMaDownloader
{
    func downloadModel() async throws -> LaMa
    {
        let url = URL(string: modelURL)!
        let urlRequest = URLRequest(url: url)
        let result: DownloadResult = try await self.session.download(for: urlRequest)
        let response = result.response as! HTTPURLResponse
        
        guard response.statusCode == 200 else {
            
            let userInfo: Dictionary<String, Any> = [NSLocalizedDescriptionKey: "Failed to download model with status code \(response.statusCode)"]
            
            throw NSError(domain: "LaMaDownloader", code: response.statusCode, userInfo: userInfo)
        }
        
        let temporaryURL = result.location
        let lama = try await self.setupModel(at: temporaryURL)
        
        return lama
    }
    
    @MainActor
    func setupModel(at url: URL) throws -> LaMa
    {
        let fileController = DTFileController.main
        let documentURL = fileController.documentUrl(withFileName: url.lastPathComponent)
        try fileController.moveFile(at: url, to: documentURL)
        
        let lama = try LaMa(contentsOf: documentURL)
        
        return lama
    }
}
