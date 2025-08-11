//
//  PhotoViewController.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/8.
//

import UIKit
import CoreML
import SwiftExtensions

public
class PhotoViewController: UIViewController
{
    // MARK: - Properties -
    
    private
    var hudView: UIView?
    
    private
    var hudLabel: UILabel?
    
    private
    var imageView: UIImageView!
    
    private
    var maskDrawingView: DTCanvasView!
    
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
    
    public override
    func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    public override
    func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
    }
    
    public override
    func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    public override
    func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
    }
    
    public
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemBackground
        self.title = "照片編輯"
        
        self.setupNavigationBar()
        self.setupToolbarItems()
        self.setupImageView()
        self.setupMaskDrawingView()
        self.setupHUD()
        
        NSLayoutConstraint.activate([
            
            // Image View - 填滿除了按鈕之外的全部區域
            self.imageView.topAnchor =*= self.view.safeAreaLayoutGuide.topAnchor + 20.0,
            self.imageView.leadingAnchor =*= self.view.leadingAnchor + 20.0,
            self.imageView.trailingAnchor =*= self.view.trailingAnchor - 20.0,
            self.imageView.bottomAnchor =*= self.view.safeAreaLayoutGuide.bottomAnchor - 20.0,
            
            // Mask Drawing View (overlays image view)
            self.maskDrawingView.topAnchor =*= self.imageView.topAnchor,
            self.maskDrawingView.leadingAnchor =*= self.imageView.leadingAnchor,
            self.maskDrawingView.trailingAnchor =*= self.imageView.trailingAnchor,
            self.maskDrawingView.bottomAnchor =*= self.imageView.bottomAnchor
        ])
    }
}

// MARK: - Private Methods -

private
extension PhotoViewController
{
    func setupNavigationBar()
    {
        let image = UIImage(systemName: "xmark")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.label)
        let closeAction = UIAction(image: image) {
            
            [weak self] _ in
            
            self?.dismiss(animated: true)
        }
        
        let closeButton = UIBarButtonItem(primaryAction: closeAction)
        self.navigationItem.leftBarButtonItem = closeButton
    }
    
    func setupToolbarItems()
    {
        let clearImage = UIImage(systemName: "trash.fill")?
            .withRenderingMode(.alwaysTemplate)
        let cancelAction = UIAction(image: clearImage) {
            
            [weak self] _ in
            
            self?.clearMaskTapped()
        }
        let clearButton = UIBarButtonItem(primaryAction: cancelAction)
        clearButton.tintColor = .white
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let config = UIImage.SymbolConfiguration(paletteColors: [.white, .systemRed])
        let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        let action = UIAction(image: image) {
            
            [weak self] _ in
            
            self?.processImageTapped()
        }
        let barButton = UIBarButtonItem(primaryAction: action)
        
        self.toolbarItems = [clearButton, spacer, barButton]
    }
    
    func setupHUD()
    {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.tintColor = UIColor.white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        
        let label = UILabel(frame: .zero)
        label.text = "處理中..."
        label.textColor = UIColor.white
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        self.hudLabel = label
        
        let stackView = UIStackView(arrangedSubviews: [indicator, label])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let hudView = UIView()
        hudView.translatesAutoresizingMaskIntoConstraints = false
        hudView.addSubview(stackView)
        
        self.hudView = hudView
        
        let effect = UIBlurEffect(style: .dark)
        let backgroundView = UIVisualEffectView(effect: effect)
        backgroundView.cornerRadius = 8.0
        backgroundView.isHidden = true
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.contentView.addSubview(hudView)
        
        self.view.addSubview(backgroundView)
        
        NSLayoutConstraint.activate([
            
            stackView.topAnchor =*= hudView.topAnchor + 10.0,
            stackView.leadingAnchor =*= hudView.leadingAnchor + 10.0,
            stackView.trailingAnchor =*= hudView.trailingAnchor - 10.0,
            stackView.bottomAnchor =*= hudView.bottomAnchor - 10.0,
            
            hudView.topAnchor =*= backgroundView.contentView.topAnchor,
            hudView.leadingAnchor =*= backgroundView.contentView.leadingAnchor,
            hudView.trailingAnchor =*= backgroundView.contentView.trailingAnchor,
            hudView.bottomAnchor =*= backgroundView.contentView.bottomAnchor,
            
            // HUD is center in the view, and size is 80*80
            backgroundView.contentView.centerXAnchor =*= self.view.centerXAnchor,
            backgroundView.contentView.centerYAnchor =*= self.view.centerYAnchor,
            backgroundView.widthAnchor >*= 80.0,
            backgroundView.widthAnchor =*= backgroundView.heightAnchor,
        ])
    }
    
    func setupImageView()
    {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = self.selectedImage
        
        self.view.addSubview(imageView)
        self.imageView = imageView
    }
    
    func setupMaskDrawingView()
    {
        let lineColor = UIColor.red.withAlphaComponent(0.5)
        
        let canvasView = DTCanvasView()
        canvasView.lineColor = lineColor
        canvasView.lineWidth = 15.0
        canvasView.backgroundColor = UIColor.clear
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(canvasView)
        self.maskDrawingView = canvasView
    }
    
    func processImageTapped()
    {
        guard let model = self.lamaModel else {
            
            self.showAlert(title: "錯誤", message: "LaMa 模型未載入")
            return
        }
        
        Task {
            
            do {
                
                let result = try await self.processImage(with: model)
                
                await MainActor.run {
                    
                    self.imageView.image = result
                }
                
            } catch {
                
                await MainActor.run {
                    
                    self.showAlert(title: "處理失敗", message: error.localizedDescription)
                }
            }
        }
    }
    
    func clearMaskTapped()
    {
        self.maskDrawingView.cleanUp()
        self.imageView.image = self.selectedImage
    }
    
    func processImage(with model: LaMa) async throws -> UIImage
    {
        let lineColor = UIColor.white
        let backgroundColor = UIColor.black
        
        let image: UIImage = self.selectedImage
        var maskImage: UIImage = self.maskDrawingView.outputImage(withLineColor: lineColor, backgroundColor: backgroundColor)
        maskImage = self.cropMaskImage(maskImage)
        maskImage = maskImage.scale(to: image.size)
        
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
    
    func cropMaskImage(_ maskImage: UIImage) -> UIImage
    {
        let rect: CGRect = self.imageView.imageRect()
        
        let newImage: UIImage? = maskImage.cgImage?.cropping(to: rect).map { UIImage(cgImage: $0) }
        
        return newImage ?? maskImage
    }
    
    func showAlert(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "確定", style: .default)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
}
