//
//  DrawOnImageVC.swift
//  Pods
//
//  Created by Dan Nilsson on 06/06/16.
//
//

import Foundation
import UIKit

class LineSegment {
    var points = [CGPoint]()
}

class DrawOnImageCanvasView : UIView {
    var path = UIBezierPath()
    var lineSegments = [LineSegment]()
    
    func overlay(image : UIImage) -> UIImage {
        let screenSize = UIScreen.mainScreen().bounds.size
        UIGraphicsBeginImageContextWithOptions(screenSize, false, UIScreen.mainScreen().scale)
        
        let aspect = (x : screenSize.width / self.frame.size.width,
                      y : screenSize.height / self.frame.size.height)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        image.drawInRect(UIScreen.mainScreen().bounds)
        
        for segment in lineSegments {
            for (i, point) in segment.points.enumerate() {
                let offsetPoint = CGPointMake(point.x * aspect.x, point.y * aspect.y)
                
                if i == 0 {
                    CGContextMoveToPoint(context, offsetPoint.x, offsetPoint.y)
                } else {
                    CGContextAddLineToPoint(context, offsetPoint.x, offsetPoint.y)
                }
            }
            
            CGContextStrokePath(context)
        }
        
        let overlay = UIGraphicsGetImageFromCurrentImageContext();
        return overlay
    }
    
    func clear() {
        self.path.removeAllPoints()
        self.lineSegments = [LineSegment]()
        self.setNeedsDisplay()
    }
    
    func beginSegmentWithPoint(point : CGPoint) {
        let segment = LineSegment()
        segment.points.append(point)
        lineSegments.append(segment)
        path.moveToPoint(point)
    }
    
    func addPointToSegment(point : CGPoint) {
        let lastSegment = lineSegments.last!
        lastSegment.points.append(point)
        path.addLineToPoint(point)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        UIColor.blackColor().setStroke()
        path.stroke()
    }
}

class DrawOnImageVC: UIViewController {
    var image : UIImage! = nil
    var imageView = UIImageView()
    var path = UIBezierPath()
    var canvasView = DrawOnImageCanvasView()
    var onSaveBlock : ((image : UIImage) -> ())! = nil
    
    func save() {
        self.imageView.image = self.canvasView.overlay(self.image)
        self.canvasView.clear()
        self.onSaveBlock(image : self.imageView.image!)
    }
    
    func close() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        if let touch = touches.first {
            canvasView.beginSegmentWithPoint(touch.locationInView(self.canvasView))
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        self.touchesMoved(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        super.touchesBegan(touches, withEvent: event)
        if let touch = touches.first {
            canvasView.addPointToSegment(touch.locationInView(self.canvasView))
            self.canvasView.setNeedsDisplay()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Draw on image"
        

        self.imageView.image = self.image
        self.view.backgroundColor = UIColor.lightGrayColor()
        self.canvasView.backgroundColor = UIColor.clearColor()
        
        self.view.addSubview(canvasView)
        self.view.addSubview(self.imageView)
        self.view.addSubview(self.canvasView)

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.canvasView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addConstraints( [
            NSLayoutConstraint(item: imageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: image.size.width * 0.85),
            NSLayoutConstraint(item: imageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: image.size.height * 0.85),
            NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 64),
            
            NSLayoutConstraint(item: canvasView, attribute: .CenterX, relatedBy: .Equal, toItem: imageView, attribute: .CenterX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: canvasView, attribute: .CenterY, relatedBy: .Equal, toItem: imageView, attribute: .CenterY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: canvasView, attribute: .Width, relatedBy: .Equal, toItem: imageView, attribute: .Width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: canvasView, attribute: .Height, relatedBy: .Equal, toItem: imageView, attribute: .Height, multiplier: 1.0, constant: 0)
            ])

        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Done, target: self, action: #selector(DrawOnImageVC.save))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(DrawOnImageVC.close))
    }
}
