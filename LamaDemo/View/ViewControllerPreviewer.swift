//
//  ViewControllerPreviewer.swift
//
//  Created by Darktt on 23/8/28.
//  Copyright © 2023 Darktt. All rights reserved.
//

import SwiftUI

public
struct ViewControllerPreviewer<ViewControllerType> where ViewControllerType: UIViewController
{
    public
    typealias UIViewControllerType = ViewControllerType
    
    private
    let creater: () -> ViewControllerType
    
    public
    init(creater: @escaping () -> ViewControllerType)
    {
        self.creater = creater
    }
}

extension ViewControllerPreviewer: UIViewControllerRepresentable
{
    public
    func makeUIViewController(context: Context) -> ViewControllerType
    {
        self.creater()
    }
    
    public
    func updateUIViewController(_ uiViewController: ViewControllerType, context: Context)
    {
        
    }
}
