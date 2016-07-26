import UIKit
import LogTape
import Alamofire

struct WeakManagerRef {
    weak var manager : Manager? = nil
}

class LogTapeAlamofire {
    static private var instance = LogTapeAlamofire()
    var requestTimes = [Int : NSDate]()
    var managers = [WeakManagerRef]()

    func addManager(manager : Manager) {
        self.managers.append(WeakManagerRef(manager: manager))
    }
    
    func removeManager(manager : Manager) {
        self.managers = self.managers.filter { $0.manager != nil && $0.manager !== manager }
    }

    public static func startLoggingWithManager(manager : Manager) {
        let initialCount = self.instance.managers.count
        
        self.instance.removeManager(manager)
        self.instance.addManager(manager)

        if initialCount == 0 {
            self.instance.registerListeners()
        }
    }

    public static func stopLoggingWithManager(manager : Manager) {
        self.instance.removeManager(manager)
        
        if self.instance.managers.count == 0 {
            self.instance.unregisterListeners()
        }
    }
    
    func registerListeners() {
        self.unregisterListeners()

        NSNotificationCenter.defaultCenter().addObserverForName(Notifications.Task.DidResume, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidStart(notification)
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(Notifications.Task.DidComplete, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidFinish(notification)
        }
    }
    
    func delegateFromTask(task : NSURLSessionTask) -> Request.TaskDelegate? {
        for manager in self.managers {
            if let manager = manager.manager, delegate = manager.delegate[task] {
                return delegate
            }
        }
        
        return nil
    }
    
    
    func networkRequestDidStart(notification : NSNotification) {
        guard let task = notification.object as? NSURLSessionTask, _ = self.delegateFromTask(task) else {
            return
        }
        
        requestTimes[task.taskIdentifier] = NSDate()
        LogTape.LogURLSessionTaskStart(task)
    }
    
    func networkRequestDidFinish(notification : NSNotification) {
        guard let task = notification.object as? NSURLSessionTask,
            startTime = requestTimes[task.taskIdentifier],
            delegate = self.delegateFromTask(task)
            else
        {
            return
        }

        let elapsedTime = NSDate().timeIntervalSinceDate(startTime)
        var error = task.error
        var data : NSData? = nil

        // Ugly hack to access private data member in TaskDelegate - I prefer
        // it to swizzling methods though, less chance of messing up internal
        // workings
        if delegate.respondsToSelector("data") {
            let res = delegate.performSelector("data")
            
            if let afData = res.takeUnretainedValue() as? NSMutableData {
                data = NSData(data: afData)
            }
        }
        
        LogTape.LogURLSessionTaskFinish(task, elapsedTime: elapsedTime, data : data, error: error)
        requestTimes.removeValueForKey(task.taskIdentifier)
    }
    
    func unregisterListeners() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

extension LogTape {
    public static func enableAlamofireLogging(manager : Manager = Manager.sharedInstance) {
        LogTapeAlamofire.startLoggingWithManager(manager)
    }
    
    public static func disableAlamofireLogging(manager : Manager = Manager.sharedInstance) {
        LogTapeAlamofire.stopLoggingWithManager(manager)
    }
}
