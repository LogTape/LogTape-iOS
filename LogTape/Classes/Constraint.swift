//
//  Constraint.swift
//  Pods
//
//  Created by Dan Nilsson on 14/07/16.
//
//

import UIKit

class Constraint {
    static func EqualWidth(_ view : UIView, toView : UIView, margin : CGFloat = 0.0, multiplier : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: toView, attribute: .width, multiplier: multiplier, constant: margin)
    }
    
    static func EqualHeight(_ view : UIView, toView : UIView, margin : CGFloat = 0.0, multiplier : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: toView, attribute: .height, multiplier: multiplier, constant: margin)
    }
    
    static func PinLeft(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: toView, attribute: .left, multiplier: 1.0, constant: margin)
    }

    static func PinLeftToRight(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: toView, attribute: .right, multiplier: 1.0, constant: margin)
    }
    
    static func PinRight(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: toView, attribute: .right, multiplier: 1.0, constant: -margin)
    }
    
    static func PinRightToLeft(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: toView, attribute: .left, multiplier: 1.0, constant: -margin)
    }
    
    static func PinTop(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: toView, attribute: .top, multiplier: 1.0, constant: margin)
    }
    
    static func PinTopToBottom(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: toView, attribute: .bottom, multiplier: 1.0, constant: margin)
    }

    static func PinBottomToTop(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: toView, attribute: .top, multiplier: 1.0, constant: margin)
    }

    static func PinBottom(_ view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: toView, attribute: .bottom, multiplier: 1.0, constant: -margin)
    }
    
    static func PinCenterX(_ view : UIView, inView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: inView, attribute: .centerX, multiplier: 1.0, constant: margin)
    }
    
    static func PinCenterY(_ view : UIView, inView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: inView, attribute: .centerY, multiplier: 1.0, constant: margin)
    }
    
    static func Width(_ view : UIView, width : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
    }
    
    static func AspectWidth(_ view : UIView, aspect : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: view, attribute: .height, multiplier: aspect, constant: 0.0)
    }
    
    static func AspectHeight(_ view : UIView, aspect : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: view, attribute: .width, multiplier: aspect, constant: 0.0)
    }
    
    static func Height(_ view : UIView, height : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
    }
}
