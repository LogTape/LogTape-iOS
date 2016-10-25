import UIKit

extension UIApplication {
    public class func lt_inject() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        // make sure this isn't a subclass
        if self !== UIApplication.self {
            return
        }
        
        dispatch_once(&Static.token) {
            let originalSelector = Selector("sendEvent:")
            let swizzledSelector = Selector("lt_sendEvent:")
            
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            
            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }
    
    // MARK: - Method Swizzling
    
    func lt_sendEvent(event : UIEvent) {
        if event.subtype == UIEventSubtype.MotionShake {
            LogTape.showReportVC()
        }
        
        self.lt_sendEvent(event)
    }
}

class LogEvent {
    static let dateFormatter = LogEvent.InitDateFormatter()
    
    static func InitDateFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }
    
    func toDictionary() -> NSDictionary {
        return NSDictionary()
    }
    
    static func currentTimeAsUTCString() -> String {
        return LogEvent.dateFormatter.stringFromDate(NSDate()) ?? ""
    }
}

class ObjectLogEvent : LogEvent {
    var object = NSDictionary()
    var message = ""
    
    init(object : NSDictionary, message : String) {
        self.object = object
        self.message = message
    }
    
    override func toDictionary() -> NSDictionary {
        return [
            "type" : "JSON",
            "message" : message,
            "timestamp" : LogEvent.currentTimeAsUTCString(),
            "data" : object
        ]
    }
}

class RequestLogEvent : LogEvent {
    var response : NSURLResponse? = nil
    var request : NSURLRequest? = nil
    var error : NSError? = nil
    var responseData : NSData? = nil
    var elapsedTime : NSTimeInterval = 0
    
    init(response : NSURLResponse?, request : NSURLRequest?, responseData : NSData?, error : NSError?, elapsedTime : NSTimeInterval) {
        self.request = request
        self.response = response
        self.error = error
        self.responseData = responseData
        self.elapsedTime = elapsedTime
    }

    override func toDictionary() -> NSDictionary {
  
        var dataString = ""
        
        if let responseData = responseData {
            dataString = String(data: responseData, encoding: NSUTF8StringEncoding) ?? ""
        }
        
        var responseDict = [NSObject : AnyObject]()
        var requestDict = [NSObject : AnyObject]()

        if let response = response as? NSHTTPURLResponse {
            responseDict = ["headers" : response.allHeaderFields,
                               "statusCode" : response.statusCode,
                               "data" : dataString,
                               "time" : elapsedTime]
        }
        
        if let request = request {
            requestDict["method"] = request.HTTPMethod
            
            if let url = request.URL {
                requestDict["url"] = url.absoluteString
            }
            
            if let headers = request.allHTTPHeaderFields {
                requestDict["headers"] = headers
            }
        }

        return [
            "type" : "REQUEST",
            "timestamp" : LogEvent.currentTimeAsUTCString(),
            "data" : [
                "response" : responseDict,
                "request" : requestDict
                ] as NSDictionary
        ]
    }
}

class MessageLogEvent : LogEvent {
    var message : String = ""
    
    init(message : String) {
        self.message = message
    }
    
    override func toDictionary() -> NSDictionary {
        return [
            "type" : "LOG",
            "timestamp" : LogEvent.currentTimeAsUTCString(),
            "data" : message
        ]
    }
}


public class LogTape {
    static private var instance : LogTape? = nil
    
    private var requestTimes = [NSURLSessionTask : NSDate]()
    private var events = [LogEvent]()
    private var apiKey = ""
    
    init(apiKey : String) {
        self.apiKey = apiKey
    }
    
    static func showReportVC() {
        LogTapeVC.show(LogTape.instance?.apiKey ?? "")
    }
    
    public static func start(apiKey : String) {
        self.instance = LogTape(apiKey : apiKey)
        UIApplication.lt_inject()
    }
    
    init() {
        
    }
    
    private func Log(message : String) {
        self.events.append(MessageLogEvent(message: message))
    }
    
    private func LogObject(object : NSDictionary, message : String = "") {
        self.events.append(ObjectLogEvent(object: object, message: message))
    }
    
    private func LogURLSessionTaskStart(task : NSURLSessionTask) {
        self.requestTimes[task] = NSDate()
    }
    
    private func LogURLSessionTaskFinish(task : NSURLSessionTask, data : NSData?, error : NSError?)
    {
        if let startTime = self.requestTimes[task] {
            let elapsedTime = NSDate().timeIntervalSinceDate(startTime)
            
            self.events.append(RequestLogEvent(response: task.response, request: task.originalRequest, responseData: data, error: error, elapsedTime : elapsedTime))
            self.requestTimes.removeValueForKey(task)
        }
    }

    // Convenience static methods
    static public func Log(message : String) {
        self.instance?.Log(message)
    }
    
    static public func LogObject(object : NSDictionary, message : String = "") {
        self.instance?.LogObject(object, message : message)
    }
    
    static public func LogURLSessionTaskStart(task : NSURLSessionTask) {
        self.instance?.LogURLSessionTaskStart(task)
    }
    
    static public func LogURLSessionTaskFinish(task : NSURLSessionTask, data : NSData?, error : NSError?)
    {
        self.instance?.LogURLSessionTaskFinish(task, data: data, error: error)
    }
    
    static var Events : [LogEvent] {
        return self.instance?.events ?? []
    }
}