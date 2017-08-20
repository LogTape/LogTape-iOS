import UIKit

extension UIApplication {
    
    public class func lt_inject() {
        // make sure this isn't a subclass
        if self !== UIApplication.self {
            return
        }

        if !LogTape.swizzled {
            LogTape.swizzled = true
            let originalSelector = #selector(UIApplication.sendEvent(_:))
            let swizzledSelector = #selector(UIApplication.lt_sendEvent(_:))
            
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
    
    func lt_sendEvent(_ event : UIEvent) {
        if event.subtype == UIEventSubtype.motionShake {
            LogTape.showReportVC()
        }
        
        if let window = UIApplication.shared.keyWindow {
            for touch in event.touches(for: window) ?? Set<UITouch>() {
                if let videoRecorder = LogTape.VideoRecorder {
                    videoRecorder.handleTouch(touch)
                }
            }
        }
        
        self.lt_sendEvent(event)
    }
}

class LogEvent {
    static let dateFormatter = LogEvent.InitDateFormatter()
    
    static func InitDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }
    
    func toDictionary() -> NSDictionary {
        return NSDictionary()
    }
    
    static func currentTimeAsUTCString() -> String {
        return LogEvent.dateFormatter.string(from: Date())
    }
}

class ObjectLogEvent : LogEvent {
    var object = NSDictionary()
    var message = NSString()
    
    init(object : NSDictionary, message : String) {
        self.object = object
        self.message = message as NSString
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
    var response : URLResponse? = nil
    var request : URLRequest? = nil
    var error : NSError? = nil
    var responseData : Data? = nil
    var elapsedTime : TimeInterval = 0
    
    init(response : URLResponse?, request : URLRequest?, responseData : Data?, error : NSError?, elapsedTime : TimeInterval) {
        self.request = request
        self.response = response
        self.error = error
        self.responseData = responseData
        self.elapsedTime = elapsedTime
    }

    override func toDictionary() -> NSDictionary {
  
        var dataString = ""
        
        if let responseData = responseData {
            dataString = String(data: responseData, encoding: String.Encoding.utf8) ?? ""
        }
        
        var responseDict = NSMutableDictionary()
        let requestDict = NSMutableDictionary()

        if let response = response as? HTTPURLResponse {
            responseDict = ["headers" : response.allHeaderFields as NSDictionary,
                            "statusCode" : response.statusCode as NSNumber,
                            "data" : dataString,
                            "time" : elapsedTime as NSNumber]
        }
        
        if let request = request {
            requestDict["method"] = request.httpMethod
            
            if let url = request.url {
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


open class LogTape {
    static var instance : LogTape? = nil
    static var swizzled = false;

    fileprivate var requestTimes = [URLSessionTask : Date]()
    fileprivate var events = [LogEvent]()
    fileprivate var apiKey = ""
    var videoRecorder = LogTapeVideoRecorder()
    var attachedScreenshots = [UIImage]()
    
    init(apiKey : String) {
        self.apiKey = apiKey
    }

    static var VideoRecorder : LogTapeVideoRecorder? {
        return instance?.videoRecorder
    }
    
    static func showReportVC() {
        LogTape.VideoRecorder?.stop()
        LogTapeVC.show(LogTape.instance?.apiKey ?? "")
    }
    
    open static func start(_ apiKey : String) {
        self.instance = LogTape(apiKey : apiKey)
        UIApplication.lt_inject()
    }
    
    init() {
        
    }
    
    fileprivate func Log(_ message : String) {
        self.events.append(MessageLogEvent(message: message))
    }
    
    fileprivate func LogObject(_ object : NSDictionary, message : String = "") {
        self.events.append(ObjectLogEvent(object: object, message: message))
    }
    
    fileprivate func LogURLSessionTaskStart(_ task : URLSessionTask) {
        self.requestTimes[task] = Date()
    }
    
    fileprivate func LogURLSessionTaskFinish(_ task : URLSessionTask, data : Data?, error : NSError?)
    {
        if let startTime = self.requestTimes[task] {
            let elapsedTimeMs = Date().timeIntervalSince(startTime) * 1000.0
            
            self.events.append(RequestLogEvent(response: task.response, request: task.originalRequest, responseData: data, error: error, elapsedTime : elapsedTimeMs))
            self.requestTimes.removeValue(forKey: task)
        }
    }

    // Convenience static methods
    static open func Log(_ message : String) {
        self.instance?.Log(message)
    }
    
    static open func LogObject(_ object : NSDictionary, message : String = "") {
        self.instance?.LogObject(object, message : message)
    }
    
    static open func LogURLSessionTaskStart(_ task : URLSessionTask) {
        self.instance?.LogURLSessionTaskStart(task)
    }
    
    static open func LogURLSessionTaskFinish(_ task : URLSessionTask, data : Data?, error : NSError?)
    {
        self.instance?.LogURLSessionTaskFinish(task, data: data, error: error)
    }
    
    static var Events : [LogEvent] {
        return self.instance?.events ?? []
    }
}
