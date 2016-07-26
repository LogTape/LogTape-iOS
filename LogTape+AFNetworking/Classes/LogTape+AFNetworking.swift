import UIKit
import LogTape
import AFNetworking

public class LogTapeAFNetworking {
    static private var instance = LogTapeAFNetworking()
    var requestTimes = [Int : NSDate]()
    
    public static func startLogging() {
        self.instance.registerListeners()
    }

    public static func stopLogging() {
        self.instance.unregisterListeners()
    }
    
    func registerListeners() {
        self.unregisterListeners()
        
        NSNotificationCenter.defaultCenter().addObserverForName(AFNetworkingTaskDidResumeNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidStart(notification)
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(AFNetworkingTaskDidCompleteNotification, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidFinish(notification)
        }
    }
    
    
    func networkRequestDidStart(notification : NSNotification) {
        guard let task = notification.object as? NSURLSessionTask else {
            return
        }
        
        requestTimes[task.taskIdentifier] = NSDate()
        LogTape.LogURLSessionTaskStart(task)
    }
    
    func networkRequestDidFinish(notification : NSNotification) {
        guard let task = notification.object as? NSURLSessionTask, startTime = requestTimes[task.taskIdentifier] else {
            return
        }

        let elapsedTime = NSDate().timeIntervalSinceDate(startTime)
        var error = task.error
        var data : NSData? = nil

        if let userInfo = notification.userInfo where error == nil {
            error = userInfo[AFNetworkingTaskDidCompleteErrorKey] as? NSError
            data = userInfo[AFNetworkingTaskDidCompleteResponseDataKey] as? NSData
        }
        
        LogTape.LogURLSessionTaskFinish(task, elapsedTime: elapsedTime, data : data, error: error)
        requestTimes.removeValueForKey(task.taskIdentifier)
    }
    
    func unregisterListeners() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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