//
//  ViewController.swift
//  LogTape
//
//  Created by Dan Nilsson on 06/05/2016.
//  Copyright (c) 2016 Dan Nilsson. All rights reserved.
//

import UIKit
import LogTape
import AFNetworking
import Alamofire

class ViewController: UIViewController {
    let sessionManager = AFURLSessionManager(sessionConfiguration: URLSessionConfiguration.default)

    var addedAnimatedViews = false
    
    @IBOutlet weak var animationContainer: UIView!
    
    func animateView(_ animView : UIView, index : Int, flipped : Bool) {
        var targetFrame = animView.frame
        if flipped {
            targetFrame.size.height = 20
            targetFrame.origin.y = 30
        } else {
            targetFrame.size.height = 50
            targetFrame.origin.y = 0
        }
        
        UIView.animate(withDuration: 1.0, delay: TimeInterval(index) * 0.2, options: [], animations: {
            animView.frame = targetFrame
        }, completion: { [weak self] (completed) in
            self?.animateView(animView, index: index, flipped: !flipped)
        })
    }
    
    func initAnimatedViews() {
        let color = UIColor(red : 95/255.0, green: 158/255.0, blue : 160/255.0, alpha : 1.0)
        for i in 0..<7 {
            let animView = UIView()
            animView.frame = CGRect(x: 40 + CGFloat(i) * 30, y: 30, width: 20, height: 20)
            animView.backgroundColor = color
            self.animationContainer.addSubview(animView)
            
            self.animateView(animView, index: i, flipped: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !addedAnimatedViews {
            self.initAnimatedViews()
        }

        LogTape.Log("Entered view controller")
        LogTape.LogObject(["Test" : "1234"], message: "Test object")

        let url = URL(string: "https://httpbin.org/get?from=afnetworking")!

        // Test AFNetworking request
        let task = sessionManager.dataTask(with: URLRequest(url: url)) { (response, object, error) in
            if let object = object {
                //print(object)
            }
        }
        
        task.resume()
        
        // Test alamofire request
        Alamofire.request("https://httpbin.org/get", parameters: ["from": "alamofire"])
            .responseJSON { response in
                if let request = response.request {
                    //print(request)  // original URL request
                }
                
                if let response = response.response {
                    //print(response) // URL response
                }
                
                if let data = response.data {
                    //print(data)     // server data
                }
                
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //print("JSON: \(JSON)")
                }
        }

        // Test manual request
        var manualTask : URLSessionTask! = nil
        
        manualTask = URLSession.shared.dataTask(with: URL(string: "https://httpbin.org/get?from=urlsession")!) {
            data, response, error in
            if let req = manualTask.originalRequest {
                LogTape.LogRequestFinished(req, response: response, data: data, error: error, tags: [:])
            }
        }

        if let req = manualTask.originalRequest {
            LogTape.LogRequestStart(req, tags: [:])
        }

        manualTask.resume()
    }
}

