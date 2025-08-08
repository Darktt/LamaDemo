//
//  PhotoViewController.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/8.
//

import UIKit
import CoreML

public
class PhotoViewController: UIViewController
{
    // MARK: - Properties -
    
    private
    var imageView: UIImageView!
    
    private
    var maskDrawingView: MaskDrawingView!
    
    private
    var processButton: UIButton!
    
    private
    var clearMaskButton: UIButton!
    
    private
    var selectedImage: UIImage
    
    private
    weak var lamaModel: LaMa?
    
    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    init(image: UIImage, lamaModel: LaMa?)
    {
        self.selectedImage = image
        self.lamaModel = lamaModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required
    init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemBackground
        self.title = "照片編輯"
        
        self.setupNavigationBar()
        self.setupImageView()
        self.setupMaskDrawingView()
        self.setupProcessButton()
        self.setupClearMaskButton()
        
        NSLayoutConstraint.activate([
            // Process Button
            self.processButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.processButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.processButton.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -10),
            self.processButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Clear Mask Button
            self.clearMaskButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.clearMaskButton.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 10),
            self.clearMaskButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            self.clearMaskButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Image View - 填滿除了按鈕之外的全部區域
            self.imageView.topAnchor.constraint(equalTo: self.processButton.bottomAnchor, constant: 20),
            self.imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.imageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            self.imageView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Mask Drawing View (overlays image view)
            self.maskDrawingView.topAnchor.constraint(equalTo: self.imageView.topAnchor),
            self.maskDrawingView.leadingAnchor.constraint(equalTo: self.imageView.leadingAnchor),
            self.maskDrawingView.trailingAnchor.constraint(equalTo: self.imageView.trailingAnchor),
            self.maskDrawingView.bottomAnchor.constraint(equalTo: self.imageView.bottomAnchor)
        ])
        
        // Set the selected image
        self.imageView.image = self.selectedImage
        self.maskDrawingView.image = self.selectedImage
    }
}

// MARK: - Private Methods -

private
extension PhotoViewController
{
    func setupNavigationBar()
    {
        let closeAction = UIAction {
            
            [weak self] _ in
            
            self?.dismiss(animated: true)
        }
        
        let closeButton = UIBarButtonItem(title: "關閉", primaryAction: closeAction)
        self.navigationItem.leftBarButtonItem = closeButton
    }
    
    func setupImageView()
    {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(imageView)
        self.imageView = imageView
    }
    
    func setupMaskDrawingView()
    {
        let maskDrawingView = MaskDrawingView()
        maskDrawingView.backgroundColor = UIColor.clear
        maskDrawingView.layer.cornerRadius = 8
        maskDrawingView.clipsToBounds = true
        maskDrawingView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(maskDrawingView)
        self.maskDrawingView = maskDrawingView
    }
    
    func setupProcessButton()
    {
        let button = UIButton(type: .system)
        button.setTitle("處理圖片", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction {
            
            [weak self] _ in
            
            self?.processImageTapped()
        }
        button.addAction(action, for: .touchUpInside)
        
        self.view.addSubview(button)
        self.processButton = button
    }
    
    func setupClearMaskButton()
    {
        let button = UIButton(type: .system)
        button.setTitle("清除遮罩", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor.systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction {
            
            [weak self] _ in
            
            self?.clearMaskTapped()
        }
        button.addAction(action, for: .touchUpInside)
        
        self.view.addSubview(button)
        self.clearMaskButton = button
    }
    
    func processImageTapped()
    {
        guard let model = self.lamaModel else {
            
            self.showAlert(title: "錯誤", message: "LaMa 模型未載入")
            return
        }
        
        self.processButton.isEnabled = false
        self.processButton.setTitle("處理中...", for: .normal)
        
        Task {
            
            do {
                
                let result = try await self.processImage(self.selectedImage, with: model)
                
                await MainActor.run {
                    
                    self.imageView.image = result
                    self.processButton.isEnabled = true
                    self.processButton.setTitle("處理圖片", for: .normal)
                }
                
            } catch {
                
                await MainActor.run {
                    
                    self.showAlert(title: "處理失敗", message: error.localizedDescription)
                    self.processButton.isEnabled = true
                    self.processButton.setTitle("處理圖片", for: .normal)
                }
            }
        }
    }
    
    func clearMaskTapped()
    {
        self.maskDrawingView.clearMask()
        self.imageView.image = self.selectedImage
    }
    
    func processImage(_ image: UIImage, with model: LaMa) async throws -> UIImage
    {
        guard let maskImage = self.maskDrawingView.generateMaskImage() else {
            
            let userInfo: [String: Any] = [NSLocalizedDescriptionKey: "請先在圖片上繪製需要修復的區域"]
            
            throw NSError(domain: "LaMaProcessing", code: -3, userInfo: userInfo)
        }
        
        let input = try LaMaInput(image: image, mask: maskImage)
        
        let output = try model.prediction(input: input)
        
        guard let outputPixelBuffer = output.output else {
            
            let userInfo: [String: Any] = [NSLocalizedDescriptionKey: "無法獲取處理結果"]
            
            throw NSError(domain: "LaMaProcessing", code: -1, userInfo: userInfo)
        }
        
        let ciImage = CIImage(cvPixelBuffer: outputPixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            
            let userInfo: [String: Any] = [NSLocalizedDescriptionKey: "無法轉換處理結果"]
            
            throw NSError(domain: "LaMaProcessing", code: -2, userInfo: userInfo)
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "確定", style: .default)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
}
