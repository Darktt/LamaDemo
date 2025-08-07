//
//  LaMaDownloader.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import Foundation
import ZIPFoundation

private
let kModelURL: String = "https://github.com/Darktt/LamaDemo/raw/refs/heads/model/model/LaMa.zip"

private
let kModelFileName: String = "LaMa.mlmodelc"

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
    func downloadModel() async throws -> LaMa
    {
        try await LaMaDownloader().downloadModel()
    }
    
    @MainActor
    public static
    func deleteModel() throws
    {
        let fileController = DTFileController.main
        let documentURL = fileController.documentUrl(withFileName: kModelFileName)
        
        guard fileController.fileExists(atUrl: documentURL) else {
            return
        }
        
        try fileController.removeFile(at: documentURL)
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
        if let lama = try await self.loadModelIfExists() {
            
            return lama
        }
        
        let url = URL(string: kModelURL)!
        let urlRequest = URLRequest(url: url)
        let result: DownloadResult = try await self.session.download(for: urlRequest)
        let response = result.response as! HTTPURLResponse
        
        guard response.statusCode == 200 else {
            
            let userInfo: Dictionary<String, Any> = [NSLocalizedDescriptionKey: "Failed to download model with status code \(response.statusCode)"]
            
            throw NSError(domain: "LaMaDownloader", code: response.statusCode, userInfo: userInfo)
        }
        
        let temporaryURL = result.location
        let unzippedURL = try await self.unzip(at: temporaryURL)
        let lama = try await self.setupModel(at: unzippedURL)
        
        return lama
    }
    
    @MainActor
    func loadModelIfExists() throws -> LaMa?
    {
        let fileController = DTFileController.main
        let documentURL = fileController.documentUrl(withFileName: kModelFileName)
        
        guard fileController.fileExists(atUrl: documentURL) else {
            
            return nil
        }
        
        let lama = try LaMa(contentsOf: documentURL)
        
        return lama
    }
    
    @MainActor
    func unzip(at url: URL) throws -> URL
    {
        let destinationFolder = url.deletingLastPathComponent()
        let destinationURL = destinationFolder.appendingPathComponent(kModelFileName)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.unzipItem(at: url, to: destinationFolder)
        
        return destinationURL
    }
    
    @MainActor
    func setupModel(at url: URL) throws -> LaMa
    {
        let fileController = DTFileController.main
        let documentURL = fileController.documentUrl(withFileName: kModelFileName)
        
        try fileController.moveFile(at: url, to: documentURL)
        let lama = try LaMa(contentsOf: documentURL)
        
        return lama
    }
}
