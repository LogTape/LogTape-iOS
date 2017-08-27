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

open class LogEvent {
    static let dateFormatter = LogEvent.InitDateFormatter()
    let timestamp = Date()
    static var idCounter = Int(0)
    let id : Int
    
    init() {
        self.id = LogEvent.idCounter
        LogEvent.idCounter += 1
    }
    
    static func InitDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }
    
    func toDictionary() -> NSDictionary {
        return NSDictionary()
    }
    
    func timestampAsUTCString() -> String {
        return LogEvent.dateFormatter.string(from: self.timestamp)
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
            "id" : self.id,
            "message" : message,
            "timestamp" : timestampAsUTCString(),
            "data" : object
        ]
    }
}

open class RequestLogStartedEvent : LogEvent {
    var request : URLRequest? = nil
    
    init(request : URLRequest?) {
        self.request = request
    }
    
    override func toDictionary() -> NSDictionary {
        let requestDict = NSMutableDictionary()
        
        if let request = request {
            requestDict["method"] = request.httpMethod

            if let requestData = request.httpBody {
                let dataString = String(data: requestData, encoding: String.Encoding.utf8) ?? ""
                requestDict["data"] = dataString
            }
            
            if let url = request.url {
                requestDict["url"] = url.absoluteString
            }
            
            if let headers = request.allHTTPHeaderFields {
                requestDict["headers"] = headers
            }
        }
        
        let data = NSMutableDictionary()
        data["request"] = requestDict
        
        let ret = NSMutableDictionary()
        ret["type"] = "REQUEST_START"
        ret["timestamp"] = timestampAsUTCString()
        ret["data"] = data
        ret["id"] = self.id
    
        return ret
    }
}

class RequestLogEvent : LogEvent {
    var response : URLResponse? = nil
    var error : NSError? = nil
    var responseData : Data? = nil
    var requestStartedEvent : RequestLogStartedEvent
    
    init(startEvent : RequestLogStartedEvent,
         response : URLResponse?, responseData : Data?,
         error : NSError?)
    {
        self.requestStartedEvent = startEvent
        self.response = response
        self.error = error
        self.responseData = responseData
    }

    override func toDictionary() -> NSDictionary {
        let ret = NSMutableDictionary(dictionary : requestStartedEvent.toDictionary())
        
        var dataString = ""
        
        if let responseData = responseData {
            dataString = String(data: responseData, encoding: String.Encoding.utf8) ?? ""
        }
        
        var responseDict = NSMutableDictionary()

        if let response = response as? HTTPURLResponse {
            let elapsedTime = self.timestamp.timeIntervalSince(self.requestStartedEvent.timestamp) * 1000
            
            responseDict = ["headers" : response.allHeaderFields as NSDictionary,
                            "statusCode" : response.statusCode as NSNumber,
                            "data" : dataString,
                            "time" : elapsedTime as NSNumber]
        }

        let dataDict = ret["data"] as! NSMutableDictionary
        dataDict["response"] = responseDict
        ret["type"] = "REQUEST"
        ret["timestamp"] = timestampAsUTCString()
        ret["id"] = self.id
        ret["startId"] = self.requestStartedEvent.id
        
        return ret
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
            "id" : self.id,
            "timestamp" : timestampAsUTCString(),
            "data" : message
        ]
    }
}


open class LogTape {
    static var instance : LogTape? = nil
    static var swizzled = false;

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
        let event = RequestLogStartedEvent(request: task.originalRequest)
        self.events.append(event)
        pendingEvents.setObject(event, forKey: task)
    }
    

    var pendingEvents = NSMapTable<URLSessionTask, RequestLogStartedEvent>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])
    
    fileprivate func LogURLSessionTaskFinish(_ task : URLSessionTask,
                                             data : Data?,
                                             error : NSError?)
    {
        if let startEvent = pendingEvents.object(forKey: task) {
            let event = RequestLogEvent(startEvent: startEvent, response: task.response, responseData: data, error: error)
            self.events.append(event)
            pendingEvents.removeObject(forKey: task)
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
