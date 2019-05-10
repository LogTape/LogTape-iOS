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
    
    func overlay(_ image : UIImage) -> UIImage {
        let screenSize = UIScreen.main.bounds.size
        UIGraphicsBeginImageContextWithOptions(screenSize, false, UIScreen.main.scale)
        
        let aspect = (x : screenSize.width / self.frame.size.width,
                      y : screenSize.height / self.frame.size.height)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.black.cgColor)
        image.draw(in: UIScreen.main.bounds)
        
        for segment in lineSegments {
            for (i, point) in segment.points.enumerated() {
                let offsetPoint = CGPoint(x: point.x * aspect.x, y: point.y * aspect.y)
                
                if i == 0 {
                    context?.move(to: CGPoint(x: offsetPoint.x, y: offsetPoint.y))
                } else {
                    context?.addLine(to: CGPoint(x: offsetPoint.x, y: offsetPoint.y))
                }
            }
            
            context?.strokePath()
        }
        
        let overlay = UIGraphicsGetImageFromCurrentImageContext();
        return overlay!
    }
    
    func clear() {
        self.path.removeAllPoints()
        self.lineSegments = [LineSegment]()
        self.setNeedsDisplay()
    }
    
    func beginSegmentWithPoint(_ point : CGPoint) {
        let segment = LineSegment()
        segment.points.append(point)
        lineSegments.append(segment)
        path.move(to: point)
    }
    
    func addPointToSegment(_ point : CGPoint) {
        let lastSegment = lineSegments.last!
        lastSegment.points.append(point)
        path.addLine(to: point)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIColor.black.setStroke()
        path.stroke()
    }
}

class DrawOnImageVC: UIViewController {
    var image : UIImage! = nil
    var imageView = UIImageView()
    var path = UIBezierPath()
    var canvasView = DrawOnImageCanvasView()
    var onSaveBlock : ((UIImage) -> ())! = nil
    
    @objc func save() {
        self.imageView.image = self.canvasView.overlay(self.image)
        self.canvasView.clear()
        self.onSaveBlock(self.imageView.image!)
    }
    
    @objc func close() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            canvasView.beginSegmentWithPoint(touch.location(in: self.canvasView))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.touchesMoved(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            canvasView.addPointToSegment(touch.location(in: self.canvasView))
            self.canvasView.setNeedsDisplay()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Draw on image"
        

        self.imageView.image = self.image
        self.view.backgroundColor = UIColor.lightGray
        self.canvasView.backgroundColor = UIColor.clear
        
        self.view.addSubview(canvasView)
        self.view.addSubview(self.imageView)
        self.view.addSubview(self.canvasView)

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.canvasView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addConstraints( [
            NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: image.size.width * 0.85),
            NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: image.size.height * 0.85),
            NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 64),
            
            NSLayoutConstraint(item: canvasView, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: canvasView, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: canvasView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: canvasView, attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1.0, constant: 0)
            ])

        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItem.Style.done, target: self, action: #selector(DrawOnImageVC.save))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(DrawOnImageVC.close))
    }
}
