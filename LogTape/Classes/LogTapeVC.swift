//
//  LogTapeVC.swift
//  Pods
//
//  Created by Dan Nilsson on 05/06/16.
//
//

import Foundation

class DialogTransitionAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    var presenting = false

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.4
    }
    
    var toVc : UIViewController? = nil
    var fromVc : UIViewController? = nil
    
    func animationEnded(transitionCompleted: Bool) {

    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toVc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        

        
        if self.presenting {
            fromVc.view.userInteractionEnabled = false
            transitionContext.containerView()?.addSubview(toVc.view)
            
            toVc.view.alpha = 0.0
            UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                fromVc.view.tintAdjustmentMode = .Dimmed
                toVc.view.alpha = 1.0
                
                }, completion: { completed in
                    transitionContext.completeTransition(true)
            })
        } else {
            toVc.view.userInteractionEnabled = true
            
            UIView.animateWithDuration(self.transitionDuration(transitionContext), animations: { () -> Void in
                fromVc.view.alpha = 0.0
                toVc.view.tintAdjustmentMode = .Automatic
                
                }, completion: { completed in
                    transitionContext.completeTransition(true)
            })
        }
    }
}

class CenteredButton : UIButton {
    override func layoutSubviews() {
        
        let spacing: CGFloat = 6.0
        
        // lower the text and push it left so it appears centered
        //  below the image
        var titleEdgeInsets = UIEdgeInsetsZero
        if let image = self.imageView?.image {
            titleEdgeInsets.left = -image.size.width
            titleEdgeInsets.bottom = -(image.size.height + spacing)
        }
        self.titleEdgeInsets = titleEdgeInsets;
        
        // raise the image and push it right so it appears centered
        //  above the text
        var imageEdgeInsets = UIEdgeInsetsZero
        if let text: NSString = self.titleLabel?.text, let font = self.titleLabel?.font {
            let attributes = [NSFontAttributeName:font]
            let titleSize = text.sizeWithAttributes(attributes)
            imageEdgeInsets.top = -(titleSize.height + spacing)
            imageEdgeInsets.right = -titleSize.width
        }
        self.imageEdgeInsets = imageEdgeInsets
        
        super.layoutSubviews()
    }
}


class InsetTextField : UITextField {
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 5, 2)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return self.textRectForBounds(bounds)
    }
}

func UIImageFromColor(color: UIColor) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    CGContextSetFillColorWithColor(context, color.CGColor)
    CGContextFillRect(context, rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img
}


class LogTapeVC : UIViewController, UIViewControllerTransitioningDelegate, UITextViewDelegate {
    var image : UIImage? = nil
    var imageView = UIImageView()
    var descriptionView = UITextView()
    var containerView = UIView()
    var loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    var apiKey = ""
    
    var dimView = UIView()
    var topLabel = UILabel()
    var primaryColor = UIColor(red : 95/255.0, green: 158/255.0, blue : 160/255.0, alpha : 1.0)
    var borderColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
    var textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    var sourceDescription = ""
    var placeholderText = "What happened?"
    var hasPlaceholderText = true
    var helpLabel = UILabel()
    var progressView = UIView()
    var submitButton : UIButton! = nil
    var cancelButton : UIButton! = nil
    var progressStatusLabel = UILabel()
    var progressStatusYConstraint : NSLayoutConstraint! = nil
    var errorLabelHeightConstraint : NSLayoutConstraint! = nil
    var inputViews = [UIView]()
    var errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let font = UIFont(name: "Avenir-Light", size: 15.0)

        self.view.opaque = false
        self.view.backgroundColor = UIColor.clearColor()

        self.view.addSubview(self.dimView)
    
        self.dimView.translatesAutoresizingMaskIntoConstraints = false
        self.dimView.opaque = false
        self.dimView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        self.dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogTapeVC.dimViewTapped)))

        self.topLabel.text = "Report issue"
        self.topLabel.textColor = UIColor.blackColor()
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        self.topLabel.font = UIFont(name: "Avenir-Medium", size: 18.0)
        self.topLabel.textColor = textColor
        self.topLabel.textAlignment = .Center

        self.errorLabel.hidden = true
        self.errorLabel.textColor = UIColor.redColor()
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.font = UIFont(name: "Avenir-Light", size: 10.0)
        self.errorLabel.textAlignment = .Center
        
        self.helpLabel.text = "Tap screenshot to draw"
        self.helpLabel.textColor = UIColor.darkGrayColor()
        self.helpLabel.translatesAutoresizingMaskIntoConstraints = false
        self.helpLabel.font = UIFont(name: "Avenir-Light", size: 10.0)
        self.helpLabel.textAlignment = .Center
        
        self.view.addSubview(self.containerView)
        
        self.view.addConstraints([
            Constraint.PinCenterX(containerView, inView: view),
            Constraint.PinCenterY(containerView, inView: view),
            Constraint.EqualWidth(containerView, toView: view, multiplier: 0.8)])
        
        self.view.addConstraints([
            Constraint.PinLeft(dimView, toView: view),
            Constraint.PinRight(dimView, toView: view),
            Constraint.PinTop(dimView, toView: view),
            Constraint.PinBottom(dimView, toView: view)])

        self.progressView.backgroundColor = UIColor.whiteColor()
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.layer.cornerRadius = 4.0
        self.progressView.alpha = 0.0
        self.progressView.hidden = true
        
        let borderWidth = 1.0 / UIScreen.mainScreen().scale
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.layer.borderWidth = borderWidth
        self.imageView.layer.borderColor = borderColor.CGColor
        self.imageView.contentMode = .ScaleAspectFit
        
        self.containerView.addSubview(imageView)

        self.containerView.backgroundColor = UIColor.whiteColor()
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.layer.borderWidth = borderWidth
        self.containerView.layer.cornerRadius = 4.0
        self.containerView.layer.borderColor = self.borderColor.CGColor
        
        self.descriptionView.font = UIFont(name: "Avenir-Light", size: 13.0)
        self.descriptionView.contentInset = UIEdgeInsetsMake(-4, 0, 0, 0)
        self.descriptionView.layer.borderColor = self.borderColor.CGColor
        self.descriptionView.layer.cornerRadius = 4.0
        self.descriptionView.layer.borderWidth = borderWidth
        self.descriptionView.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionView.delegate = self
        
        self.containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogTapeVC.containerTapped)))
        self.descriptionView.textColor = UIColor.lightGrayColor()
        self.descriptionView.text = self.placeholderText
        
        self.descriptionView.translatesAutoresizingMaskIntoConstraints = false
        
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogTapeVC.imageTapped)))
        self.imageView.userInteractionEnabled = true

        if let image = self.image {
            self.imageView.image = self.image
            
            let aspect = image.size.height / image.size.width
            
            self.containerView.addConstraints([
                Constraint.PinCenterX(imageView, inView: containerView),
                Constraint.PinTop(imageView, toView: containerView, margin: 40),
                Constraint.EqualWidth(imageView, toView: containerView, multiplier: 0.33),
                Constraint.AspectHeight(imageView, aspect: aspect)])
        }
        
        inputViews.append(imageView)
        inputViews.append(helpLabel)

        self.containerView.addSubview(self.topLabel)
        self.containerView.addConstraints([
            Constraint.PinLeft(topLabel, toView: containerView, margin: 10),
            Constraint.PinRight(topLabel, toView: containerView, margin: 10),
            Constraint.PinTop(topLabel, toView: containerView, margin: 10),
            Constraint.Height(topLabel, height: 25)])
        
        self.containerView.addSubview(self.progressView)
    
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        self.progressView.addSubview(loadingIndicator)
        self.progressView.addConstraints([
            Constraint.PinCenterX(loadingIndicator, inView: progressView),
            Constraint.PinCenterY(loadingIndicator, inView: progressView),
            ])
        
        self.progressView.addSubview(progressStatusLabel)
        progressStatusYConstraint = Constraint.PinCenterY(progressStatusLabel, inView: progressView, margin: 35.0)


        self.progressView.addConstraints([
            Constraint.PinLeft(progressStatusLabel, toView: progressView, margin: 10),
            Constraint.PinRight(progressStatusLabel, toView: progressView, margin: 10),
            progressStatusYConstraint
            ])

        progressStatusLabel.font = font?.fontWithSize(12.0)
        progressStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        progressStatusLabel.text = "Uploading.."
        progressStatusLabel.textAlignment = .Center
        progressStatusLabel.textColor = textColor
        
        self.containerView.addSubview(self.helpLabel)
        self.containerView.addConstraints([
            Constraint.PinLeft(helpLabel, toView: containerView, margin: 10),
            Constraint.PinRight(helpLabel, toView: containerView, margin: 10),
            Constraint.PinTopToBottom(helpLabel, toView: imageView, margin: 2),
            Constraint.Height(helpLabel, height: 25.0)])
        
        var line = self.addLine(helpLabel, margin: 2.0)
        inputViews.append(line)
        var button = self.addIconButton("Record video", icon: "movie_icon", action: #selector(LogTapeVC.recordVideo), topView: line, leftView: containerView)
        inputViews.append(button)
        
        button = self.addIconButton("Add screenshot", icon: "camera_icon", action: #selector(LogTapeVC.addScreenshot), topView: line, leftView: button)
        inputViews.append(button)
        button = self.addIconButton("1 attachment", icon: "paperclip_icon", action: #selector(LogTapeVC.viewAttachments), topView: line, leftView: button)
        inputViews.append(button)
        
        line = self.addLine(button, margin : 5.0)
        inputViews.append(line)

        self.containerView.addSubview(self.errorLabel)
        
        self.errorLabelHeightConstraint = Constraint.Height(errorLabel, height: 0)
        self.containerView.addConstraints([
            Constraint.PinLeft(errorLabel, toView: containerView, margin: 10),
            Constraint.PinRight(errorLabel, toView: containerView, margin: 10),
            Constraint.PinTopToBottom(errorLabel, toView: line, margin: 5),
            errorLabelHeightConstraint
            ])
        
        self.containerView.addSubview(self.descriptionView)
        inputViews.append(descriptionView)
        self.containerView.addConstraints([
            Constraint.PinLeft(descriptionView, toView: containerView, margin: 10),
            Constraint.PinRight(descriptionView, toView: containerView, margin: 10),
            Constraint.PinTopToBottom(descriptionView, toView: errorLabel, margin: 5),
            Constraint.Height(descriptionView, height: 60)])
        
        submitButton = addButton("Upload", action : #selector(LogTapeVC.upload), topView : descriptionView, isCancel: false)
        cancelButton = addButton("Cancel", action : #selector(LogTapeVC.cancel), topView : submitButton, isCancel: true)

        inputViews.append(submitButton)

        self.containerView.addConstraints([
            Constraint.PinLeft(progressView, toView: containerView),
            Constraint.PinRight(progressView, toView: containerView),
            Constraint.PinBottomToTop(progressView, toView: submitButton),
            Constraint.PinTopToBottom(progressView, toView: topLabel)
            ])
        
        self.containerView.bringSubviewToFront(self.progressView)
    }

    func dimViewTapped() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageTapped() {
        self.view.endEditing(true)
        let drawVc = DrawOnImageVC()
        drawVc.image = self.image

        drawVc.onSaveBlock = { image in
            self.imageView.image = image
            self.image = image
            self.dismissViewControllerAnimated(true, completion: nil)
        }

        let nav = UINavigationController(rootViewController: drawVc)
        self.presentViewController(nav, animated: true, completion: nil)
    }

    func containerTapped() {
        self.view.endEditing(true)
    }
    
    func cancel() {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func uploadFailed() {
        self.submitButton.enabled = true
        self.cancelButton.enabled = true
        self.dimView.userInteractionEnabled = true
        
        UIView.animateWithDuration(0.3, animations: { 
            self.progressView.alpha = 0.0
            }) { (completed) in
                self.progressView.hidden = true
        }

        self.errorLabel.hidden = false
        self.errorLabel.text = "Failed to upload. Try again."
        errorLabelHeightConstraint.constant = 15.0
        
        UIView.animateWithDuration(0.4) {
            self.view.layoutIfNeeded()
        }
    }
    
    func uploadSuccessfulWithNumber(number : Int) {
        self.dimView.userInteractionEnabled = true
        let bgImage = UIImageFromColor(self.primaryColor)
        cancelButton.setBackgroundImage(bgImage, forState: UIControlState.Normal)
        self.cancelButton.setTitle("Done", forState: .Normal)
        self.cancelButton.enabled = true
        self.cancelButton.layoutIfNeeded()

        for inputView in inputViews {
            inputView.removeFromSuperview()
        }
        
        loadingIndicator.stopAnimating()
        self.submitButton.enabled = true
        self.progressStatusLabel.text = "Uploaded successfully with ID \(number)."
        
        let constraint = Constraint.PinTopToBottom(self.cancelButton, toView: self.topLabel, margin: 80)
        constraint.priority = 1000
        self.containerView.addConstraint(constraint)

        UIView.animateWithDuration(0.4) {
            self.view.layoutIfNeeded()
        }
    }
    
    func upload() {
        self.progressView.alpha = 0.0
        self.containerView.bringSubviewToFront(self.progressView)
        self.progressView.hidden = false
        
        self.submitButton.enabled = false
        self.cancelButton.enabled = false
        
        var request = NSMutableURLRequest(URL: NSURL(string: "https://www.logtape.io:443/api/issues")!)
        let base64Data = ("issues:" + self.apiKey).dataUsingEncoding(NSUTF8StringEncoding)
        let authString = base64Data?.base64EncodedStringWithOptions([]) ?? ""
        var body = [String : AnyObject]()
        var properties = NSMutableArray()

        if let image = self.image, pngImage = UIImagePNGRepresentation(image)
        {
            let imageData = pngImage.base64EncodedStringWithOptions([])
            body["images"] = [ imageData ]
        }

        if self.hasPlaceholderText {
            body["title"] = ""
        } else {
            body["title"] = self.descriptionView.text
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        
        var bundle = NSBundle.mainBundle()
        
        if let releaseVersionnumber = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            properties.addObject(["label" : "App version", "value" : releaseVersionnumber])
        }
        
        if let buildVersionnumber = bundle.infoDictionary?["CFBundleVersion"] as? String {
            properties.addObject(["label" : "Build", "value" : buildVersionnumber])
        }
        
        let device = UIDevice.currentDevice()
        properties.addObject(["label" : "Device type", "value" : device.model])
        properties.addObject(["label" : "OS Version", "value" : "\(device.systemName) \(device.systemVersion)"])
        properties.addObject(["label" : "Description", "value" : self.descriptionView.text])
        
        let eventsArray : NSArray = LogTape.Events.map { $0.toDictionary() }
        body["events"] = eventsArray
        body["timestamp"] = LogEvent.currentTimeAsUTCString()
        body["properties"] = properties
        
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(body, options: [])
        
        request.HTTPMethod = "POST"
        request.HTTPBody = jsonData
        self.dimView.userInteractionEnabled = false
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            dispatch_async(dispatch_get_main_queue(), { 
                if let error = error {
                    self.uploadFailed()
                } else {
                    
                    if let data = data, jsonStr = String(data: data, encoding: NSUTF8StringEncoding) {
                        print(jsonStr)
                    }
                    
                    if let data = data,
                        dict = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
                        issueNumber = dict["issueNumber"] as? Int,
                        response = response as? NSHTTPURLResponse where (response.statusCode / 100) == 2
                    {
                        self.uploadSuccessfulWithNumber(issueNumber)
                    } else {
                        self.uploadFailed()
                    }
                }
            })
        }
        
        task.resume()
        
        UIView.animateWithDuration(0.3) { 
            self.progressView.alpha = 1.0
        }
    }

    func viewAttachments() {
        let alert = UIAlertView(title: "Info", message: "Sorry, not implemented yet!", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func addScreenshot() {
        let alert = UIAlertView(title: "Info", message: "Sorry, not implemented yet!", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }

    func recordVideo() {
        let alert = UIAlertView(title: "Info", message: "Sorry, not implemented yet!", delegate: nil, cancelButtonTitle: "OK")

        alert.show()
    }
    
    func addLine(topView : UIView, margin : CGFloat) -> UIView {
        var lineView = UIView()
        lineView.backgroundColor = self.borderColor.colorWithAlphaComponent(0.6)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(lineView)

        self.containerView.addConstraints([
            Constraint.PinLeft(lineView, toView: containerView),
            Constraint.PinRight(lineView, toView: containerView),
            Constraint.PinTopToBottom(lineView, toView: topView, margin: margin),
            Constraint.Height(lineView, height: 1.0 / UIScreen.mainScreen().scale)
            ])
        
        return lineView
    }
    
    func loadImage(name: String) -> UIImage? {
        let podBundle = NSBundle(forClass: LogTapeVC.self)
        if let url = podBundle.URLForResource("LogTape", withExtension: "bundle") {
            let bundle = NSBundle(URL: url)
            return UIImage(named: name, inBundle: bundle, compatibleWithTraitCollection: nil)
        }
        return nil
    }
    
    func addIconButton(title : String, icon : String, action : Selector, topView : UIView, leftView : UIView) -> UIView {
        let button = CenteredButton(type: .Custom)
        button.setImage(loadImage(icon), forState: .Normal)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 9.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, forState: .Normal)
        button.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)

        self.containerView.addSubview(button)
        self.containerView.addConstraints([
            leftView == containerView ?
                Constraint.PinLeft(button, toView: leftView) : Constraint.PinLeftToRight(button, toView: leftView),
            Constraint.EqualWidth(button, toView: containerView, multiplier: 1.0/3.0),
            Constraint.Height(button, height: 40.0),
            Constraint.PinTopToBottom(button, toView: topView, margin: 10)
            ])
       
        return button
    }
    
    func addButton(title : String, action : Selector, topView : UIView, isCancel : Bool) -> UIButton {
        let button = UIButton(type: .Custom)

        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 15.0)
        let color : UIColor
        if isCancel {
            color = UIColor.lightGrayColor()
        } else {
            color = self.primaryColor
        }
        
        let bgImage = UIImageFromColor(color)
        button.setBackgroundImage(bgImage, forState: UIControlState.Normal)
        button.clipsToBounds = true
        button.layer.cornerRadius = 5.0
        button.setTitle(title, forState: .Normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(button)
        
        let topConstraint = Constraint.PinTopToBottom(button, toView: topView, margin: 10)
        topConstraint.priority = 750

        self.containerView.addConstraints([
            Constraint.PinLeft(button, toView: containerView, margin: 10),
            Constraint.PinRight(button, toView: containerView, margin: 10),
            Constraint.Height(button, height: 30),
            topConstraint
            ])
        
        if isCancel {
            self.containerView.addConstraints([
                NSLayoutConstraint(item: containerView, attribute: .Bottom, relatedBy: .Equal, toItem: button, attribute: .Bottom, multiplier: 1.0, constant: 10),
                ])
        }
        
        return button
    }

    static var showing = false
    
    override func viewDidDisappear(animated: Bool) {
        LogTapeVC.showing = false
        super.viewDidDisappear(animated)
    }
    
    
    static func topViewControllerWithRootViewController(rootVc : UIViewController?) -> UIViewController?
    {
        if let tabBarController = rootVc as? UITabBarController {
            return self.topViewControllerWithRootViewController(tabBarController.selectedViewController)
        } else if let navController = rootVc as? UINavigationController {
            return self.topViewControllerWithRootViewController(navController.visibleViewController)
        } else if let presentedController = rootVc?.presentedViewController {
            return self.topViewControllerWithRootViewController(presentedController)
        } else {
            return rootVc
        }
    }
    
    static func topViewController() -> UIViewController? {
        return self.topViewControllerWithRootViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
    }
    
    static func show(apiKey : String) {
        if let topVc = LogTapeVC.topViewController(), window = UIApplication.sharedApplication().keyWindow where !LogTapeVC.showing {
            
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.mainScreen().scale)
            window.drawViewHierarchyInRect(window.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext();
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            UIGraphicsEndImageContext()

            let root = LogTapeVC()
            root.apiKey = apiKey
            root.modalPresentationStyle = .Custom
            root.transitioningDelegate = root
            root.image = image
            root.sourceDescription = topVc.navigationItem.title ?? NSStringFromClass(topVc.dynamicType).componentsSeparatedByString(".").last!
            LogTapeVC.showing = true
            topVc.presentViewController(root, animated: true, completion: nil)
        }
    }
    
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = DialogTransitionAnimator()
        animator.presenting = true
        return animator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator =  DialogTransitionAnimator()
        return animator
    }
    
    // MARK: UITextViewDelegate methods
    func textViewDidEndEditing(textView: UITextView) {
        
        if textView.text == "" {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = self.placeholderText
            self.hasPlaceholderText = true
        }
        
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        
        if self.hasPlaceholderText {
            textView.textColor = textColor
            textView.text = ""
            self.hasPlaceholderText = false
        }
    }
}