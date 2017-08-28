import UIKit
import LogTape
import AFNetworking

open class LogTapeAFNetworking {
    static fileprivate var instance = LogTapeAFNetworking()
    
    open static func startLogging() {
        self.instance.registerListeners()
    }

    open static func stopLogging() {
        self.instance.unregisterListeners()
    }
    
    func registerListeners() {
        self.unregisterListeners()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AFNetworkingTaskDidResume, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidStart(notification)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AFNetworkingTaskDidComplete, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidFinish(notification)
        }
    }
    
    
    func networkRequestDidStart(_ notification : Notification) {
        guard let task = notification.object as? URLSessionTask, let req = task.originalRequest else {
            return
        }
        
        LogTape.LogRequestStart(req, tags: [:])
    }
    
    func networkRequestDidFinish(_ notification : Notification) {
        guard let task = notification.object as? URLSessionTask, let req = task.originalRequest else {
            return
        }
        
        var error = task.error
        var data : Data? = nil

        if let userInfo = (notification as NSNotification).userInfo , error == nil {
            error = userInfo[AFNetworkingTaskDidCompleteErrorKey] as? NSError
            data = userInfo[AFNetworkingTaskDidCompleteResponseDataKey] as? Data
        }
        
        LogTape.LogRequestFinished(req, response: task.response, data: data, error: error, tags: [:])
    }
    
    func unregisterListeners() {
        NotificationCenter.default.removeObserver(self)
    }
}

extension LogTape {
    public static func enableAFNetworkLogging() {
        LogTapeAFNetworking.startLogging()
    }
    
    public static func disableAFNetworkLogging() {
        LogTapeAFNetworking.stopLogging()
    }
}
