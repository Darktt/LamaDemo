//
//  DTCanvasView.swift
//
//  Created by Darktt on 18/9/12.
//  Copyright © 2018 Darktt. All rights reserved.
//

import UIKit

@MainActor
public
class DTCanvasView: UIView
{
    // MARK: - Properties -
    
    /// Default is black color.
    public
    var lineColor: UIColor = UIColor.black
    
    /// Default is 1.0.
    public
    var lineWidth: CGFloat = 1.0
    
    /// Default is NO.
    public
    var clipToPath: Bool = false
    
    /**
     Detect canvas can be undo,
     This is property key value observing able.
     */
    public private(set)
    var canUndo: Bool = false
    
    /**
     Detect canvas can be redo,
     This is property key value observing able.
     */
    public private(set)
    var canRedo: Bool = false
    
    public override
    var isUserInteractionEnabled: Bool {
        
        set {
            // Do noting in here.
        }
        
        get {
            
            return true
        }
    }
    
    private
    var paths: Array<UIBezierPath> = []
    
    private
    var undoPaths: Array<UIBezierPath> = []
    
    private
    weak var path: UIBezierPath?
    
    private
    var finalPath: UIBezierPath = UIBezierPath()
    
    private
    var points: (previous1: CGPoint, previous2: CGPoint, current: CGPoint) = (CGPoint.zero, CGPoint.zero, CGPoint.zero)
    
    // MARK: - Methods -
    // MARK: Public Methods
    
    public
    func outputImage() -> UIImage
    {
        let image: UIImage = self.outputImage(withLineColor: self.lineColor)
        
        return image
    }
    
    public
    func outputImage(withLineColor lineColor: UIColor, backgroundColor: UIColor? = nil) -> UIImage
    {
        guard !self.finalPath.isEmpty else {
            
            return UIImage()
        }
        
        let newPath = self.finalPath
        var bounds: CGRect = self.bounds
        
        if self.clipToPath {
            
            bounds = newPath.bounds
            bounds.origin.x -= self.lineWidth * 2.0
            bounds.origin.y -= self.lineWidth * 2.0
            bounds.size.width += self.lineWidth * 4.0
            bounds.size.height += self.lineWidth * 4.0
            
            // Move path to (0, 0) position.
            let point: CGPoint = bounds.origin
            let transform = CGAffineTransform(translationX: -point.x, y: -point.y)
            
            newPath.apply(transform)
        }
        
        let actions: UIGraphicsImageRenderer.DrawingActions = {
            
            [unowned self] context in
            
            backgroundColor.map {
                
                $0.setFill()
                context.fill(bounds)
            }
            
            lineColor.setStroke()
            newPath.lineWidth = self.lineWidth
            newPath.stroke()
        }
        
        let image: UIImage = UIGraphicsImageRenderer(bounds: bounds).image(actions: actions)
        
        return image
    }
    
    public
    func undo()
    {
        guard let path: UIBezierPath = self.paths.last else {
            
            return
        }
        
        self.paths.removeLast()
        self.undoPaths.append(path)
        
        self.updateState()
        self.setNeedsDisplay()
    }
    
    public
    func redo()
    {
        guard let path: UIBezierPath = self.undoPaths.last else {
            
            return
        }
        
        self.paths.append(path)
        self.undoPaths.removeLast()
        
        self.updateState()
        self.setNeedsDisplay()
    }
    
    public
    func cleanUp()
    {
        self.undoPaths.removeAll()
        self.undoPaths = self.paths
        self.paths.removeAll()
        
        self.updateState()
        self.setNeedsDisplay()
    }
    
    // MARK: Override Methods
    
    public override
    func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        self.lineColor.setStroke()
        
        self.finalPath.removeAllPoints()
        self.paths.forEach {
            
            self.finalPath.append($0)
        }
        
        self.finalPath.lineWidth = self.lineWidth
        self.finalPath.lineCapStyle = .round
        self.finalPath.lineJoinStyle = .round
        self.finalPath.miterLimit = -10.0
        self.finalPath.stroke()
    }
    
    public override
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard touches.count == 1 else {
            
            self.isUserInteractionEnabled = false
            self.isUserInteractionEnabled = true
            return
        }
        
        let touch: UITouch = touches.first!
        let point1: CGPoint = touch.previousLocation(in: self)
        let point2: CGPoint = touch.previousLocation(in: self)
        let current: CGPoint = touch.location(in: self)
        
        self.points = (point1, point2, current)
        
        let path = UIBezierPath()
        path.lineWidth = self.lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.miterLimit = -10.0
        path.move(to: current)
        
        self.path = path
        self.addPath(path)
    }
    
    public override
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch: UITouch = touches.first, let path = self.path else {
            
            return
        }
        
        let point1: CGPoint = touch.previousLocation(in: self)
        let current: CGPoint = touch.location(in: self)
        
        self.points = (point1, self.points.previous1, current)
        
        let midPoint1: CGPoint = self.points.previous1._midPoint(to: self.points.previous2)
        let midPoint2: CGPoint = self.points.current._midPoint(to: self.points.previous1)
        
        path.move(to: midPoint1)
        path.addQuadCurve(to: midPoint2, controlPoint: self.points.previous1)
        self.setNeedsDisplay()
    }
    
    public override
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.path = nil
        self.setNeedsDisplay()
    }
    
    public override
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.path = nil
        self.setNeedsDisplay()
    }
}

// MARK: - Private Methods -

private
extension DTCanvasView
{
    func updateState()
    {
        self.canUndo = (self.paths.count > 0)
        self.canRedo = (self.undoPaths.count > 0)
    }
    
    func addPath(_ path: UIBezierPath)
    {
        self.canUndo = true
        self.canRedo = false
        self.paths.append(path)
        self.undoPaths.removeAll()
    }
}

// MARK: - Private Extension -

private
extension CGPoint
{
    func _midPoint(to point: CGPoint) -> CGPoint
    {
        let dx: CGFloat = (self.x + point.x) / 2.0
        let dy: CGFloat = (self.y + point.y) / 2.0
        
        return CGPoint(x: dx, y: dy)
    }
}
