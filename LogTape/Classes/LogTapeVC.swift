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

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    var toVc : UIViewController? = nil
    var fromVc : UIViewController? = nil
    
    func animationEnded(_ transitionCompleted: Bool) {

    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVc = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVc = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        

        
        if self.presenting {
            fromVc.view.isUserInteractionEnabled = false
            transitionContext.containerView.addSubview(toVc.view)
            
            toVc.view.alpha = 0.0
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: { () -> Void in
                fromVc.view.tintAdjustmentMode = .dimmed
                toVc.view.alpha = 1.0
                
                }, completion: { completed in
                    transitionContext.completeTransition(true)
            })
        } else {
            toVc.view.isUserInteractionEnabled = true
            
            UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: { () -> Void in
                fromVc.view.alpha = 0.0
                toVc.view.tintAdjustmentMode = .automatic
                
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
        var titleEdgeInsets = UIEdgeInsets.zero
        if let image = self.imageView?.image {
            titleEdgeInsets.left = -image.size.width
            titleEdgeInsets.bottom = -(image.size.height + spacing)
        }
        self.titleEdgeInsets = titleEdgeInsets;
        
        // raise the image and push it right so it appears centered
        //  above the text
        var imageEdgeInsets = UIEdgeInsets.zero
        if let text: NSString = self.titleLabel?.text as NSString?, let font = self.titleLabel?.font {
            let attributes = [NSFontAttributeName:font]
            let titleSize = text.size(attributes: attributes)
            imageEdgeInsets.top = -(titleSize.height + spacing)
            imageEdgeInsets.right = -titleSize.width
        }
        self.imageEdgeInsets = imageEdgeInsets
        
        super.layoutSubviews()
    }
}


class InsetTextField : UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 5, dy: 2)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }
}

func UIImageFromColor(_ color: UIColor) -> UIImage {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img!
}


class LogTapeVC : UIViewController, UIViewControllerTransitioningDelegate, UITextViewDelegate {
    var image : UIImage? = nil
    var imageView = UIImageView()
    var descriptionView = UITextView()
    var containerView = UIView()
    var loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
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

        self.view.isOpaque = false
        self.view.backgroundColor = UIColor.clear

        self.view.addSubview(self.dimView)
    
        self.dimView.translatesAutoresizingMaskIntoConstraints = false
        self.dimView.isOpaque = false
        self.dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogTapeVC.dimViewTapped)))

        self.topLabel.text = "Report issue"
        self.topLabel.textColor = UIColor.black
        self.topLabel.translatesAutoresizingMaskIntoConstraints = false
        self.topLabel.font = UIFont(name: "Avenir-Medium", size: 18.0)
        self.topLabel.textColor = textColor
        self.topLabel.textAlignment = .center

        self.errorLabel.isHidden = true
        self.errorLabel.textColor = UIColor.red
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.font = UIFont(name: "Avenir-Light", size: 10.0)
        self.errorLabel.textAlignment = .center
        
        self.helpLabel.text = "Tap screenshot to draw"
        self.helpLabel.textColor = UIColor.darkGray
        self.helpLabel.translatesAutoresizingMaskIntoConstraints = false
        self.helpLabel.font = UIFont(name: "Avenir-Light", size: 10.0)
        self.helpLabel.textAlignment = .center
        
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

        self.progressView.backgroundColor = UIColor.white
        self.progressView.translatesAutoresizingMaskIntoConstraints = false
        self.progressView.layer.cornerRadius = 4.0
        self.progressView.alpha = 0.0
        self.progressView.isHidden = true
        
        let borderWidth = 1.0 / UIScreen.main.scale
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.layer.borderWidth = borderWidth
        self.imageView.layer.borderColor = borderColor.cgColor
        self.imageView.contentMode = .scaleAspectFit
        
        self.containerView.addSubview(imageView)

        self.containerView.backgroundColor = UIColor.white
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.layer.borderWidth = borderWidth
        self.containerView.layer.cornerRadius = 4.0
        self.containerView.layer.borderColor = self.borderColor.cgColor
        
        self.descriptionView.font = UIFont(name: "Avenir-Light", size: 13.0)
        self.descriptionView.contentInset = UIEdgeInsetsMake(-4, 0, 0, 0)
        self.descriptionView.layer.borderColor = self.borderColor.cgColor
        self.descriptionView.layer.cornerRadius = 4.0
        self.descriptionView.layer.borderWidth = borderWidth
        self.descriptionView.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionView.delegate = self
        
        self.containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogTapeVC.containerTapped)))
        self.descriptionView.textColor = UIColor.lightGray
        self.descriptionView.text = self.placeholderText
        
        self.descriptionView.translatesAutoresizingMaskIntoConstraints = false
        
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LogTapeVC.imageTapped)))
        self.imageView.isUserInteractionEnabled = true

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

        progressStatusLabel.font = font?.withSize(12.0)
        progressStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        progressStatusLabel.text = "Uploading.."
        progressStatusLabel.textAlignment = .center
        progressStatusLabel.textColor = textColor
        progressStatusLabel.numberOfLines = 0
        
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
        
        var numAttachments = 1 + (LogTape.instance?.attachedScreenshots.count ?? 0)
        
        if (LogTape.VideoRecorder?.duration() ?? 0.0) > 0.0 {
            numAttachments += 1
        }
        
        button = self.addIconButton(numAttachments == 1 ? "1 attachment" : "\(numAttachments) attachments", icon: "paperclip_icon", action: #selector(LogTapeVC.viewAttachments), topView: line, leftView: button)
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
        
        self.containerView.bringSubview(toFront: self.progressView)
    }

    func dimViewTapped() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func imageTapped() {
        self.view.endEditing(true)
        let drawVc = DrawOnImageVC()
        drawVc.image = self.image

        drawVc.onSaveBlock = { image in
            self.imageView.image = image
            self.image = image
            self.dismiss(animated: true, completion: nil)
        }

        let nav = UINavigationController(rootViewController: drawVc)
        nav.navigationBar.tintColor = self.primaryColor
        self.present(nav, animated: true, completion: nil)
    }

    func containerTapped() {
        self.view.endEditing(true)
    }
    
    func cancel() {
        LogTape.instance?.attachedScreenshots = []
        LogTape.VideoRecorder?.clear()
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func uploadFailed() {
        self.submitButton.isEnabled = true
        self.cancelButton.isEnabled = true
        self.dimView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.3, animations: { 
            self.progressView.alpha = 0.0
            }, completion: { (completed) in
                self.progressView.isHidden = true
        }) 

        self.errorLabel.isHidden = false
        self.errorLabel.text = "Failed to upload. Try again."
        errorLabelHeightConstraint.constant = 15.0
        
        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        }) 
    }
    
    func uploadSuccessfulWithNumber(_ number : Int, deletedIssueNumber : Int?) {
        self.dimView.isUserInteractionEnabled = true
        let bgImage = UIImageFromColor(self.primaryColor)
        cancelButton.setBackgroundImage(bgImage, for: UIControlState())
        self.cancelButton.setTitle("Done", for: UIControlState())
        self.cancelButton.isEnabled = true
        self.cancelButton.layoutIfNeeded()

        for inputView in inputViews {
            inputView.removeFromSuperview()
        }
        
        loadingIndicator.stopAnimating()
        self.submitButton.isEnabled = true
        
        var extraInfo = ""
        
        if let deletedIssueNumber = deletedIssueNumber {
            extraInfo = "\nDeleted issue with ID \(deletedIssueNumber) to make room (oldest issue)."
        }
        
        self.progressStatusLabel.text = "Uploaded successfully with ID \(number)." + extraInfo
        
        let constraint = Constraint.PinTopToBottom(self.cancelButton, toView: self.topLabel, margin: 80)
        constraint.priority = 1000
        self.containerView.addConstraint(constraint)

        UIView.animate(withDuration: 0.4, animations: {
            self.view.layoutIfNeeded()
        }) 
    }

    func className(object : AnyObject) -> String {
        return NSStringFromClass(type(of: object))
    }
    
    func upload() {
        self.progressView.alpha = 0.0
        self.containerView.bringSubview(toFront: self.progressView)
        self.progressView.isHidden = false
        
        self.submitButton.isEnabled = false
        self.cancelButton.isEnabled = false
        
        //let request = NSMutableURLRequest(url: URL(string: "https://www.logtape.io/api/issues")!)
        let request = NSMutableURLRequest(url: URL(string: "http://www.localtape.io:3000/api/issues")!)

        let base64Data = ("issues:" + self.apiKey).data(using: String.Encoding.utf8)
        let authString = base64Data?.base64EncodedString(options: []) ?? ""
        let body = NSMutableDictionary()
        let properties = NSMutableDictionary()

        if let image = self.image, let pngImage = UIImagePNGRepresentation(image)
        {
            let imageData = pngImage.base64EncodedString(options: []) as NSString
            
            let images = NSMutableArray()
            images.add(imageData)
            
            for attachedImage in (LogTape.instance?.attachedScreenshots ?? []) {
                if let pngImage = UIImagePNGRepresentation(attachedImage) {
                    let attachedImageData = pngImage.base64EncodedString(options: []) as NSString
                    images.add(attachedImageData)
                }
            }
            
            body["images"] = images
        }

        if self.hasPlaceholderText {
            body["title"] = NSString()
        } else {
            body["title"] = NSString(string : self.descriptionView.text ?? "")
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        
        let bundle = Bundle.main
        
        if let releaseVersionnumber = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            properties["App version"] = releaseVersionnumber
        }
        
        if let buildVersionNumber = bundle.infoDictionary?["CFBundleVersion"] as? String {
            properties["Build"] = buildVersionNumber
        }
        
        let device = UIDevice.current
        properties["Device type"] = device.model
        properties["OS Version"] = "\(device.systemName) \(device.systemVersion)"
        properties["Description"] = self.descriptionView.text
        
        let eventsArray = LogTape.Events.map { $0.toDictionary() } as NSArray
        body["events"] = eventsArray
        body["timestamp"] = LogEvent.dateFormatter.string(from: Date()) as NSString
        body["properties"] = properties

        request.httpMethod = "POST"
        self.dimView.isUserInteractionEnabled = false
        
        if let recorder = LogTape.VideoRecorder, recorder.duration() > 0.0 {
            recorder.writeToFile({ (path) in
                
                if let moviePath = path, let movieData = try? Data(contentsOf: URL(fileURLWithPath: moviePath))
                {
                    let movieBase64Str = movieData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
                    body["movies"] = [movieBase64Str]
                }
                self.uploadWithRequest(request: request,
                                       body : body)
            })
        } else {
            self.uploadWithRequest(request: request, body : body)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.progressView.alpha = 1.0
        })
    }
    
    func uploadWithRequest(request : NSMutableURLRequest, body : NSMutableDictionary) {
        let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
            DispatchQueue.main.async(execute: {
                if let _ = error {
                    self.uploadFailed()
                } else {
                    
                    if let data = data, let jsonStr = String(data: data, encoding: String.Encoding.utf8) {
                        print(jsonStr)
                    }
                    
                    if let data = data,
                        let dict = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary,
                        let issueNumber = dict["issueNumber"] as? Int,
                        let response = response as? HTTPURLResponse , (response.statusCode / 100) == 2
                    {
                        let deletedIssueNumber = dict["deletedIssueNumber"] as? Int
                        
                        self.uploadSuccessfulWithNumber(issueNumber, deletedIssueNumber : deletedIssueNumber)
                    } else {
                        self.uploadFailed()
                    }
                }
            })
        })
        
        task.resume()
    }
    
    func viewAttachments() {
        let numImages = 1 + (LogTape.instance?.attachedScreenshots.count ?? 0)
        
        var infoStr = numImages == 1 ? "You have 1 image attached" : "You have \(numImages) images attached"
        
        if ((LogTape.instance?.videoRecorder.duration() ?? 0.0) != 0.0) {
            infoStr += " and 1 movie."
        } else {
            infoStr += "."
        }

        infoStr += " Cancel upload dialog to clear attachments."

        let alert = UIAlertView(title: "Info", message: infoStr, delegate: nil, cancelButtonTitle: "OK")

        alert.show()
    }
    
    func addScreenshot() {
        if let image = self.image, let instance = LogTape.instance {
            instance.attachedScreenshots.append(image)
        }

        self.presentingViewController?.dismiss(animated: true, completion: {
            
        })
    }


    func recordVideo() {
        self.presentingViewController?.dismiss(animated: true, completion: { 
            LogTape.VideoRecorder?.start()
        })
    }

    func addLine(_ topView : UIView, margin : CGFloat) -> UIView {
        let lineView = UIView()
        lineView.backgroundColor = self.borderColor.withAlphaComponent(0.6)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(lineView)

        self.containerView.addConstraints([
            Constraint.PinLeft(lineView, toView: containerView),
            Constraint.PinRight(lineView, toView: containerView),
            Constraint.PinTopToBottom(lineView, toView: topView, margin: margin),
            Constraint.Height(lineView, height: 1.0 / UIScreen.main.scale)
            ])
        
        return lineView
    }
    
    func loadImage(_ name: String) -> UIImage? {
        let podBundle = Bundle(for: LogTapeVC.self)
        if let url = podBundle.url(forResource: "LogTape", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
        return nil
    }
    
    func addIconButton(_ title : String, icon : String, action : Selector, topView : UIView, leftView : UIView) -> UIView {
        let button = CenteredButton(type: .custom)
        button.setImage(loadImage(icon), for: UIControlState())
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 9.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: UIControlState())
        button.setTitleColor(UIColor.darkGray, for: UIControlState())
        button.addTarget(self, action: action, for: .touchUpInside)

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
    
    func addButton(_ title : String, action : Selector, topView : UIView, isCancel : Bool) -> UIButton {
        let button = UIButton(type: .custom)

        button.addTarget(self, action: action, for: .touchUpInside)
        button.titleLabel?.font = UIFont(name: "Avenir-Light", size: 15.0)
        let color : UIColor
        if isCancel {
            color = UIColor.lightGray
        } else {
            color = self.primaryColor
        }
        
        let bgImage = UIImageFromColor(color)
        button.setBackgroundImage(bgImage, for: UIControlState())
        button.clipsToBounds = true
        button.layer.cornerRadius = 5.0
        button.setTitle(title, for: UIControlState())
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
                NSLayoutConstraint(item: containerView, attribute: .bottom, relatedBy: .equal, toItem: button, attribute: .bottom, multiplier: 1.0, constant: 10),
                ])
        }
        
        return button
    }

    static var showing = false
    
    override func viewDidDisappear(_ animated: Bool) {
        LogTapeVC.showing = false
        super.viewDidDisappear(animated)
    }
    
    
    static func topViewControllerWithRootViewController(_ rootVc : UIViewController?) -> UIViewController?
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
        return self.topViewControllerWithRootViewController(UIApplication.shared.keyWindow?.rootViewController)
    }
    
    static func show(_ apiKey : String) {
        if let topVc = LogTapeVC.topViewController(), let window = UIApplication.shared.keyWindow , !LogTapeVC.showing {
            
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            let image = UIGraphicsGetImageFromCurrentImageContext();
            //UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
            UIGraphicsEndImageContext()

            let root = LogTapeVC()
            root.apiKey = apiKey
            root.modalPresentationStyle = .custom
            root.transitioningDelegate = root
            root.image = image
            root.sourceDescription = topVc.navigationItem.title ?? NSStringFromClass(type(of: topVc)).components(separatedBy: ".").last!
            LogTapeVC.showing = true
            topVc.present(root, animated: true, completion: nil)
        }
    }
    
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = DialogTransitionAnimator()
        animator.presenting = true
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator =  DialogTransitionAnimator()
        return animator
    }
    
    // MARK: UITextViewDelegate methods
    func textViewDidEndEditing(_ textView: UITextView) {
        
        if textView.text == "" {
            textView.textColor = UIColor.lightGray
            textView.text = self.placeholderText
            self.hasPlaceholderText = true
        }
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if self.hasPlaceholderText {
            textView.textColor = textColor
            textView.text = ""
            self.hasPlaceholderText = false
        }
    }
}
