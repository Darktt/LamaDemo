//
//  ViewController.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/7.
//

import UIKit
import CoreML

public
class ViewController: UIViewController
{
    // MARK: - Properties -
    
    private
    var titleLabel: UILabel?
    
    private
    var statusLabel: UILabel?

    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    override
    func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupUI()
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
        self.setupConstraints()
    }
    
    func setupTitleLabel()
    {
        let titleLabel = UILabel()
        titleLabel.text = "LamaDemo"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(titleLabel)
        self.titleLabel = titleLabel
    }
    
    func setupStatusLabel()
    {
        let statusLabel = UILabel()
        statusLabel.text = "Welcome to LamaDemo"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 16)
        statusLabel.textColor = UIColor.secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(statusLabel)
        self.statusLabel = statusLabel
    }
    
    func setupConstraints()
    {
        guard let titleLabel = self.titleLabel,
              let statusLabel = self.statusLabel else {
            
            return
        }
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -40),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20),
            
            statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        ])
    }
}
