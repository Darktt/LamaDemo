//
//  ViewController.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import UIKit
import CoreML
import PhotosUI
import SwiftExtensions

public
class ViewController: UIViewController
{
    // MARK: - Properties -
    
    private
    var titleLabel: UILabel!
    
    private
    var statusLabel: UILabel!
    
    private
    var selectPhotoButton: UIButton!
    
    private
    var lamaModel: LaMa?

    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.systemBackground
        
        self.setupTitleLabel()
        self.setupStatusLabel()
        self.setupSelectPhotoButton()
        
        NSLayoutConstraint.activate([
            // Title
            self.titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 20),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20),
            
            // Status
            self.statusLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 10),
            self.statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            
            // Select Photo Button
            self.selectPhotoButton.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 40),
            self.selectPhotoButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.selectPhotoButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            self.selectPhotoButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -40),
            self.selectPhotoButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        self.loadModel()
    }
}

// MARK: - Actions -

private
extension ViewController
{
    func selectPhotoTapped()
    {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        self.present(picker, animated: true)
    }
}

// MARK: - Private Methods -

private
extension ViewController
{
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
    
    func setupSelectPhotoButton()
    {
        let action = UIAction(title: "") {
            
            [weak self] _ in
            
            self?.selectPhotoTapped()
        }
        
        let button = UIButton(type: .system)
        button.setTitle("選擇照片...", for: .normal)
        button.setTitleColor(.gray, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = nil
        button.cornerRadius = 8.0
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(withColor: .systemBlue, for: .normal)
        button.setBackgroundImage(withColor: .darkGray, for: .disabled)
        button.setTitleColor(.white, for: .normal)
        button.addAction(action, for: .touchUpInside)
        
        self.view.addSubview(button)
        self.selectPhotoButton = button
    }
    
    func loadModel()
    {
        Task {
            
            do {
                
                await MainActor.run {
                    
                    self.statusLabel.text = "正在下載 LaMa 模型..."
                }
                
                let model = try await LaMaDownloader.downloadModel()
                
                await MainActor.run {
                    
                    self.lamaModel = model
                    self.statusLabel.text = "模型載入完成，請選擇照片"
                    self.selectPhotoButton.isEnabled = true
                }
                
            } catch {
                
                await MainActor.run {
                    
                    self.statusLabel.text = "模型載入失敗: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func presentPhotoViewController(with image: UIImage)
    {
        let photoViewController = PhotoViewController(image: image, lamaModel: self.lamaModel)
        let navigationController = UINavigationController(rootViewController: photoViewController)
        navigationController.modalPresentationStyle = .fullScreen
        
        self.present(navigationController, animated: true)
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
        result.itemProvider.loadObject(ofClass: UIImage.self) {
            
            [weak self] object, error in
            
            guard let image = object as? UIImage else {
                
                DispatchQueue.main.async {
                    
                    self?.statusLabel.text = "無法載入選擇的照片"
                }
                return
            }
            
            DispatchQueue.main.async {
                
                let size: CGSize = image.size * 0.8
                let compressedImage: UIImage = image.scale(to: size)
                
                self?.presentPhotoViewController(with: compressedImage)
            }
        }
    }
}

public
func * (left: CGSize, right: CGFloat) -> CGSize
{
    return CGSize(width: left.width * right, height: left.height * right)
}
