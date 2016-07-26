//
//  Constraint.swift
//  Pods
//
//  Created by Dan Nilsson on 14/07/16.
//
//

import UIKit

class Constraint {
    static func EqualWidth(view : UIView, toView : UIView, margin : CGFloat = 0.0, multiplier : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: toView, attribute: .Width, multiplier: multiplier, constant: margin)
    }
    
    static func EqualHeight(view : UIView, toView : UIView, margin : CGFloat = 0.0, multiplier : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: toView, attribute: .Height, multiplier: multiplier, constant: margin)
    }
    
    static func PinLeft(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: toView, attribute: .Left, multiplier: 1.0, constant: margin)
    }

    static func PinLeftToRight(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Left, relatedBy: .Equal, toItem: toView, attribute: .Right, multiplier: 1.0, constant: margin)
    }
    
    static func PinRight(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: toView, attribute: .Right, multiplier: 1.0, constant: -margin)
    }
    
    static func PinRightToLeft(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Right, relatedBy: .Equal, toItem: toView, attribute: .Left, multiplier: 1.0, constant: -margin)
    }
    
    static func PinTop(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: toView, attribute: .Top, multiplier: 1.0, constant: margin)
    }
    
    static func PinTopToBottom(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: toView, attribute: .Bottom, multiplier: 1.0, constant: margin)
    }

    static func PinBottomToTop(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: toView, attribute: .Top, multiplier: 1.0, constant: margin)
    }

    static func PinBottom(view : UIView, toView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: toView, attribute: .Bottom, multiplier: 1.0, constant: -margin)
    }
    
    static func PinCenterX(view : UIView, inView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: inView, attribute: .CenterX, multiplier: 1.0, constant: margin)
    }
    
    static func PinCenterY(view : UIView, inView : UIView, margin : CGFloat = 0.0) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: inView, attribute: .CenterY, multiplier: 1.0, constant: margin)
    }
    
    static func Width(view : UIView, width : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: width)
    }
    
    static func AspectWidth(view : UIView, aspect : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: aspect, constant: 0.0)
    }
    
    static func AspectHeight(view : UIView, aspect : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: aspect, constant: 0.0)
    }
    
    static func Height(view : UIView, height : CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: height)
    }
}