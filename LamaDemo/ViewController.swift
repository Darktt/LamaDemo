//
//  ViewController.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import UIKit
import CoreML
import PhotosUI

public
class ViewController: UIViewController
{
    // MARK: - Properties -
    
    private
    var titleLabel: UILabel?
    
    private
    var statusLabel: UILabel?
    
    private
    var selectImageButton: UIButton?
    
    private
    var processButton: UIButton?
    
    private
    var imageView: UIImageView?
    
    private
    var resultImageView: UIImageView?
    
    private
    var lamaModel: LaMa?
    
    private
    var selectedImage: UIImage?

    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupUI()
        self.loadModel()
    }
}

// MARK: - Private Methods -

private
extension ViewController
{
    func setupUI()
    {
        self.view.backgroundColor = UIColor.systemBackground
        
        self.setupTitleLabel()
        self.setupStatusLabel()
        self.setupSelectImageButton()
        self.setupProcessButton()
        self.setupImageViews()
        self.setupConstraints()
    }
    
    func setupTitleLabel()
    {
        let titleLabel = UILabel()
        titleLabel.text = "LaMa Demo"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(titleLabel)
        self.titleLabel = titleLabel
    }
    
    func setupStatusLabel()
    {
        let statusLabel = UILabel()
        statusLabel.text = "載入 LaMa 模型中..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = UIColor.secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(statusLabel)
        self.statusLabel = statusLabel
    }
    
    func setupSelectImageButton()
    {
        let button = UIButton(type: .system)
        button.setTitle("選擇圖片", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction { [weak self] _ in
            self?.selectImageTapped()
        }
        button.addAction(action, for: .touchUpInside)
        
        self.view.addSubview(button)
        self.selectImageButton = button
    }
    
    func setupProcessButton()
    {
        let button = UIButton(type: .system)
        button.setTitle("處理圖片", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = UIColor.systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let action = UIAction { [weak self] _ in
            self?.processImageTapped()
        }
        button.addAction(action, for: .touchUpInside)
        
        self.view.addSubview(button)
        self.processButton = button
    }
    
    func setupImageViews()
    {
        // Original image view
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(imageView)
        self.imageView = imageView
        
        // Result image view
        let resultImageView = UIImageView()
        resultImageView.contentMode = .scaleAspectFit
        resultImageView.backgroundColor = UIColor.systemGray6
        resultImageView.layer.cornerRadius = 8
        resultImageView.clipsToBounds = true
        resultImageView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(resultImageView)
        self.resultImageView = resultImageView
    }
    
    func setupConstraints()
    {
        guard let titleLabel = self.titleLabel,
              let statusLabel = self.statusLabel,
              let selectImageButton = self.selectImageButton,
              let processButton = self.processButton,
              let imageView = self.imageView,
              let resultImageView = self.resultImageView else {
            
            return
        }
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20),
            
            // Status
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            
            // Buttons
            selectImageButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            selectImageButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            selectImageButton.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -10),
            selectImageButton.heightAnchor.constraint(equalToConstant: 44),
            
            processButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            processButton.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 10),
            processButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            processButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Image views
            imageView.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -10),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            resultImageView.topAnchor.constraint(equalTo: processButton.bottomAnchor, constant: 20),
            resultImageView.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 10),
            resultImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            resultImageView.heightAnchor.constraint(equalTo: resultImageView.widthAnchor),
            
            resultImageView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    func loadModel()
    {
        Task {
            
            do {
                
                await MainActor.run {
                    
                    self.statusLabel?.text = "正在下載 LaMa 模型..."
                }
                
                let model = try await LaMaDownloader.downloadModel()
                
                await MainActor.run {
                    
                    self.lamaModel = model
                    self.statusLabel?.text = "模型載入完成，請選擇圖片"
                    self.selectImageButton?.isEnabled = true
                }
                
            } catch {
                
                await MainActor.run {
                    
                    self.deleteModel()
                    self.statusLabel?.text = "模型載入失敗: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deleteModel()
    {
        do {
            
            try LaMaDownloader.deleteModel()
            self.loadModel()
        } catch {
            
            self.statusLabel?.text = "刪除模型失敗: \(error.localizedDescription)"
        }
    }
    
    func selectImageTapped()
    {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        self.present(picker, animated: true)
    }
    
    func processImageTapped()
    {
        guard let image = self.selectedImage,
              let model = self.lamaModel else {
            
            return
        }
        
        self.processButton?.isEnabled = false
        self.statusLabel?.text = "處理圖片中..."
        
        Task {
            
            do {
                
                let result = try await self.processImage(image, with: model)
                
                await MainActor.run {
                    
                    self.resultImageView?.image = result
                    self.statusLabel?.text = "圖片處理完成"
                    self.processButton?.isEnabled = true
                }
                
            } catch {
                
                await MainActor.run {
                    
                    self.statusLabel?.text = "圖片處理失敗: \(error.localizedDescription)"
                    self.processButton?.isEnabled = true
                }
            }
        }
    }
    
    func processImage(_ image: UIImage, with model: LaMa) async throws -> UIImage
    {
        // 創建一個簡單的遮罩（這裡示範用白色遮罩）
        let maskImage = self.createSimpleMask(for: image)
        
        let input = try LaMaInput(image: image, mask: maskImage)
        let options = MLPredictionOptions()
        
        let output = try model.prediction(input: input, options: options)
        
        guard let outputPixelBuffer = output.output else {
            
            let userInfo: Dictionary<String, Any> = [NSLocalizedDescriptionKey: "無法獲取處理結果"]
            
            throw NSError(domain: "LaMaProcessing", code: -1, userInfo: userInfo)
        }
        
        let ciImage = CIImage(cvPixelBuffer: outputPixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            
            let userInfo: Dictionary<String, Any> = [NSLocalizedDescriptionKey: "無法轉換處理結果"]
            
            throw NSError(domain: "LaMaProcessing", code: -2, userInfo: userInfo)
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func createSimpleMask(for image: UIImage) -> UIImage
    {
        let size = CGSize(width: 800, height: 800)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        // 創建一個中央的白色圓形遮罩
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.black.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        context?.setFillColor(UIColor.white.cgColor)
        let centerX = size.width / 2
        let centerY = size.height / 2
        let radius: CGFloat = 100
        
        context?.fillEllipse(in: CGRect(x: centerX - radius, y: centerY - radius, width: radius * 2, height: radius * 2))
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return maskImage ?? UIImage()
    }
}

// MARK: - Delegate Methods -
// MARK: #PHPickerViewControllerDelegate

extension ViewController: PHPickerViewControllerDelegate
{
    public
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
    {
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            
            return
        }
        
        let loadImageHandler: (NSItemProvider) -> Void = { [weak self] itemProvider in
            
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                
                guard let image = object as? UIImage else {
                    
                    return
                }
                
                DispatchQueue.main.async {
                    
                    self?.selectedImage = image
                    self?.imageView?.image = image
                    self?.processButton?.isEnabled = true
                    self?.statusLabel?.text = "圖片已選擇，點擊處理按鈕開始處理"
                }
            }
        }
        
        loadImageHandler(result.itemProvider)
    }
}
