//
//  PhotoViewController.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/8.
//

import UIKit
import CoreML
import SwiftExtensions

private
enum ProcessState: String
{
    case processing = "處理中..."
    
    case completed = "處理完成"
    
    case failed = "處理失敗"
}

public
class PhotoViewController: UIViewController
{
    // MARK: - Properties -
    
    private
    var hudView: UIView!
    
    private
    var hudLabel: UILabel!
    
    private
    var scrollView: UIScrollView!
    
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
        self.view.backgroundColor = .systemBackground
        
        self.setupNavigationBar()
        self.setupToolbarItems()
        self.setupScrollView()
        self.setupImageView()
        self.setupMaskDrawingView()
        self.setupHUD()
        
        NSLayoutConstraint.activate([
            
            self.scrollView.topAnchor =*= self.view.safeAreaLayoutGuide.topAnchor,
            self.scrollView.leadingAnchor =*= self.view.leadingAnchor,
            self.scrollView.trailingAnchor =*= self.view.trailingAnchor,
            self.scrollView.bottomAnchor =*= self.view.safeAreaLayoutGuide.bottomAnchor,
            
            self.imageView.topAnchor =*= self.scrollView.contentLayoutGuide.topAnchor,
            self.imageView.leadingAnchor =*= self.scrollView.contentLayoutGuide.leadingAnchor,
            self.imageView.trailingAnchor =*= self.scrollView.contentLayoutGuide.trailingAnchor,
            self.imageView.bottomAnchor =*= self.scrollView.contentLayoutGuide.bottomAnchor,
            
            self.maskDrawingView.topAnchor =*= self.imageView.topAnchor,
            self.maskDrawingView.leadingAnchor =*= self.imageView.leadingAnchor,
            self.maskDrawingView.trailingAnchor =*= self.imageView.trailingAnchor,
            self.maskDrawingView.bottomAnchor =*= self.imageView.bottomAnchor,
        ])
        
        let imageSize = self.selectedImage.size
        
        if imageSize.width <= imageSize.height {
            
            let ratio = imageSize.width / imageSize.height
            
            self.imageView.widthAnchor =*= self.scrollView.frameLayoutGuide.widthAnchor
            self.imageView.heightAnchor =*= self.imageView.widthAnchor / ratio
        } else {
            
            let ratio = imageSize.height / imageSize.width
            
            self.imageView.heightAnchor =*= self.scrollView.frameLayoutGuide.heightAnchor
            self.imageView.widthAnchor =*= self.imageView.heightAnchor / ratio
        }
    }
}

// MARK: - Actions -

private
extension PhotoViewController
{
    func clearMaskTapped()
    {
        self.maskDrawingView.cleanUp()
        self.imageView.image = self.selectedImage
    }
    
    func processImageTapped()
    {
        guard let model = self.lamaModel else {
            
            self.showAlert(title: "錯誤", message: "LaMa 模型未載入")
            return
        }
        
        self.hudView.isHidden = false
        self.hudLabel.text = ProcessState.processing.rawValue
        
        Task {
            
            do {
                
                let result = try await self.processImage(with: model)
                
                await MainActor.run {
                    
                    self.imageView.image = result
                    self.hudView.isHidden = true
                    self.hudLabel.text = ProcessState.completed.rawValue
                }
                
            } catch {
                
                await MainActor.run {
                    
                    self.hudView.isHidden = true
                    
                    let title: String = ProcessState.failed.rawValue
                    self.showAlert(title: title, message: error.localizedDescription)
                }
            }
        }
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
        label.text = ProcessState.processing.rawValue
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
        
        let effect = UIBlurEffect(style: .systemChromeMaterial)
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
    
    func setupScrollView()
    {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        
        self.view.addSubview(scrollView)
        self.scrollView = scrollView
    }
    
    func setupImageView()
    {
        let imageView = UIImageView(frame: .zero)
        imageView.image = self.selectedImage
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        
        self.scrollView.addSubview(imageView)
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
        
        self.imageView.addSubview(canvasView)
        self.maskDrawingView = canvasView
    }
    
    func processImage(with model: LaMa) async throws -> UIImage
    {
        let lineColor = UIColor.white
        let backgroundColor = UIColor.black
        
        let image: UIImage = self.selectedImage
        var maskImage: UIImage = self.maskDrawingView.outputImage(withLineColor: lineColor, backgroundColor: backgroundColor)
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
