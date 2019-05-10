import UIKit
import LogTape
import Alamofire

struct WeakManagerRef {
    weak var manager : SessionManager? = nil
}

class LogTapeAlamofire {
    static fileprivate var instance = LogTapeAlamofire()
    var managers = [WeakManagerRef]()

    func addManager(_ manager : SessionManager) {
        self.managers.append(WeakManagerRef(manager: manager))
    }
    
    func removeManager(_ manager : SessionManager) {
        self.managers = self.managers.filter { $0.manager != nil && $0.manager !== manager }
    }

    public static func startLoggingWithManager(_ manager : SessionManager) {
        let initialCount = self.instance.managers.count
        
        self.instance.removeManager(manager)
        self.instance.addManager(manager)

        if initialCount == 0 {
            self.instance.registerListeners()
        }
    }

    public static func stopLoggingWithManager(_ manager : SessionManager) {
        self.instance.removeManager(manager)
        
        if self.instance.managers.count == 0 {
            self.instance.unregisterListeners()
        }
    }
    
    func registerListeners() {
        self.unregisterListeners()

        NotificationCenter.default.addObserver(forName : Notification.Name.Task.DidResume, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidStart(notification)
        }
        
        NotificationCenter.default.addObserver(forName : Notification.Name.Task.DidComplete, object: nil, queue: nil) { [weak self] (notification) in
            self?.networkRequestDidFinish(notification)
        }
    }
    
    func delegateFromTask(_ task : URLSessionTask) -> TaskDelegate? {
        for manager in self.managers {
            if let manager = manager.manager, let delegate = manager.delegate[task]?.delegate {
                return delegate
            }
        }
        
        return nil
    }
    
    
    func networkRequestDidStart(_ notification : Notification) {        
        guard let userInfo = notification.userInfo,
            let task = userInfo[Notification.Key.Task] as? URLSessionTask,
            let req = task.originalRequest
            else
        {
            return
        }
        
        LogTape.LogRequestStart(req, tags: [:])
    }
    
    func networkRequestDidFinish(_ notification : Notification) {
        guard let userInfo = notification.userInfo,
            let task = userInfo[Notification.Key.Task] as? URLSessionTask,
            let delegate = self.delegateFromTask(task),
            let req = task.originalRequest
            else
        {
            return
        }
        
        let error = task.error
        var data : Data? = nil

        if let afData = delegate.data {
            let nsData = afData as NSData
            data = nsData.copy() as? Data
        }
        
        LogTape.LogRequestFinished(req, response: task.response, data: data, error: error, tags: [:])
    }
    
    func unregisterListeners() {
        NotificationCenter.default.removeObserver(self)
    }
}

extension LogTape {
    public static func enableAlamofireLogging(_ manager : SessionManager = SessionManager.default) {
        LogTapeAlamofire.startLoggingWithManager(manager)
    }
    
    public static func disableAlamofireLogging(_ manager : SessionManager = SessionManager.default) {
        LogTapeAlamofire.stopLoggingWithManager(manager)
    }
}
