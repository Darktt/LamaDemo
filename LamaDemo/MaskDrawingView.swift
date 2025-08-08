//
//  MaskDrawingView.swift
//  LamaDemo
//
//  Created by Eden on 2025/8/8.
//

import UIKit

public
class MaskDrawingView: UIView
{
    // MARK: - Properties -
    
    private
    var paths: [UIBezierPath] = []
    
    private
    var currentPath: UIBezierPath?
    
    public
    var brushSize: CGFloat = 20.0
    
    public
    var image: UIImage? {
        
        didSet {
            
            self.setNeedsDisplay()
        }
    }
    
    // MARK: - Methods -
    // MARK: Initial Method
    
    public
    override
    init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.setupView()
    }
    
    required
    init?(coder: NSCoder)
    {
        super.init(coder: coder)
        
        self.setupView()
    }
    
    // MARK: Drawing Methods
    
    public
    override
    func draw(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else {
            
            return
        }
        
        // 繪製遮罩路徑
        context.setStrokeColor(UIColor.red.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(self.brushSize)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for path in self.paths {
            
            path.stroke()
        }
        
        if let currentPath = self.currentPath {
            
            currentPath.stroke()
        }
    }
    
    // MARK: Touch Handling
    
    public
    override
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else {
            
            return
        }
        
        let point = touch.location(in: self)
        
        self.currentPath = UIBezierPath()
        self.currentPath?.move(to: point)
        self.currentPath?.lineWidth = self.brushSize
    }
    
    public
    override
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first,
              let currentPath = self.currentPath else {
            
            return
        }
        
        let point = touch.location(in: self)
        currentPath.addLine(to: point)
        
        self.setNeedsDisplay()
    }
    
    public
    override
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let currentPath = self.currentPath else {
            
            return
        }
        
        self.paths.append(currentPath)
        self.currentPath = nil
        
        self.setNeedsDisplay()
    }
    
    public
    override
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.currentPath = nil
        self.setNeedsDisplay()
    }
}

// MARK: - Private Methods -

private
extension MaskDrawingView
{
    func setupView()
    {
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
    }
    
    func imageRect(for image: UIImage, in bounds: CGRect) -> CGRect
    {
        let imageAspect = image.size.width / image.size.height
        let boundsAspect = bounds.width / bounds.height
        
        var imageRect: CGRect
        
        if imageAspect > boundsAspect {
            
            // 圖片較寬，以寬度為準
            let height = bounds.width / imageAspect
            imageRect = CGRect(x: 0, y: (bounds.height - height) / 2, width: bounds.width, height: height)
        } else {
            
            // 圖片較高，以高度為準
            let width = bounds.height * imageAspect
            imageRect = CGRect(x: (bounds.width - width) / 2, y: 0, width: width, height: bounds.height)
        }
        
        return imageRect
    }
}

// MARK: - Public Methods -

public
extension MaskDrawingView
{
    func clearMask()
    {
        self.paths.removeAll()
        self.currentPath = nil
        self.setNeedsDisplay()
    }
    
    func generateMaskImage() -> UIImage?
    {
        guard let image = self.image else {
            
            return nil
        }
        
        let size = CGSize(width: 800, height: 800)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            
            UIGraphicsEndImageContext()
            return nil
        }
        
        // 設置黑色背景
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        // 計算縮放比例
        let imageRect = self.imageRect(for: image, in: self.bounds)
        let scaleX = size.width / imageRect.width
        let scaleY = size.height / imageRect.height
        let scale = min(scaleX, scaleY)
        
        // 計算偏移
        let scaledImageSize = CGSize(width: imageRect.width * scale, height: imageRect.height * scale)
        let offsetX = (size.width - scaledImageSize.width) / 2
        let offsetY = (size.height - scaledImageSize.height) / 2
        
        // 繪製白色遮罩路徑
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(self.brushSize * scale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for path in self.paths {
            
            let scaledPath = UIBezierPath()
            
            path.cgPath.applyWithBlock { 
                
                element in
                
                switch element.pointee.type {
                    
                case .moveToPoint:
                    let point = element.pointee.points[0]
                    let scaledPoint = CGPoint(
                        x: (point.x - imageRect.minX) * scale + offsetX,
                        y: (point.y - imageRect.minY) * scale + offsetY
                    )
                    scaledPath.move(to: scaledPoint)
                    
                case .addLineToPoint:
                    let point = element.pointee.points[0]
                    let scaledPoint = CGPoint(
                        x: (point.x - imageRect.minX) * scale + offsetX,
                        y: (point.y - imageRect.minY) * scale + offsetY
                    )
                    scaledPath.addLine(to: scaledPoint)
                    
                case .addQuadCurveToPoint:
                    let controlPoint = element.pointee.points[0]
                    let point = element.pointee.points[1]
                    let scaledControlPoint = CGPoint(
                        x: (controlPoint.x - imageRect.minX) * scale + offsetX,
                        y: (controlPoint.y - imageRect.minY) * scale + offsetY
                    )
                    let scaledPoint = CGPoint(
                        x: (point.x - imageRect.minX) * scale + offsetX,
                        y: (point.y - imageRect.minY) * scale + offsetY
                    )
                    scaledPath.addQuadCurve(to: scaledPoint, controlPoint: scaledControlPoint)
                    
                case .addCurveToPoint:
                    let controlPoint1 = element.pointee.points[0]
                    let controlPoint2 = element.pointee.points[1]
                    let point = element.pointee.points[2]
                    let scaledControlPoint1 = CGPoint(
                        x: (controlPoint1.x - imageRect.minX) * scale + offsetX,
                        y: (controlPoint1.y - imageRect.minY) * scale + offsetY
                    )
                    let scaledControlPoint2 = CGPoint(
                        x: (controlPoint2.x - imageRect.minX) * scale + offsetX,
                        y: (controlPoint2.y - imageRect.minY) * scale + offsetY
                    )
                    let scaledPoint = CGPoint(
                        x: (point.x - imageRect.minX) * scale + offsetX,
                        y: (point.y - imageRect.minY) * scale + offsetY
                    )
                    scaledPath.addCurve(to: scaledPoint, controlPoint1: scaledControlPoint1, controlPoint2: scaledControlPoint2)
                    
                case .closeSubpath:
                    scaledPath.close()
                    
                @unknown default:
                    break
                }
            }
            
            scaledPath.stroke()
        }
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return maskImage
    }
}