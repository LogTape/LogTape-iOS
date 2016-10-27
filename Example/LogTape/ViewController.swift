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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        LogTape.Log("Entered view controller")
        LogTape.LogObject(["Test" : "1234"], message: "Test object")

        let url = URL(string: "https://httpbin.org/get?from=afnetworking")!

        // Test AFNetworking request
        let task = sessionManager.dataTask(with: URLRequest(url: url)) { (response, object, error) in
            print(object)
        }
        
        task.resume()
        
        // Test alamofire request
        Alamofire.request("https://httpbin.org/get", parameters: ["from": "alamofire"])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
        }
    }
}

