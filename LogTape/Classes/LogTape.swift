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
    let tags : [String : String]

    
    init(tags : [String : String]) {
        self.id = LogEvent.idCounter
        LogEvent.idCounter += 1
        self.tags = tags
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
    
    init(object : NSDictionary, message : String, tags : [String : String]) {
        super.init(tags: tags)
        self.object = object
        self.message = message as NSString
    }
    
    override func toDictionary() -> NSDictionary {
        return [
            "type" : "JSON",
            "id" : self.id,
            "message" : message,
            "timestamp" : timestampAsUTCString(),
            "data" : object,
            "tags" : self.tags
        ]
    }
}

open class RequestLogStartedEvent : LogEvent {
    var request : URLRequest? = nil

    init(request : URLRequest?, tags : [String : String]) {
        super.init(tags: tags)
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
        ret["tags"] = self.tags
        
        return ret
    }
}

class RequestLogEvent : LogEvent {
    var response : URLResponse? = nil
    var error : Error? = nil
    var responseData : Data? = nil
    var requestStartedEvent : RequestLogStartedEvent
    
    init(startEvent : RequestLogStartedEvent,
         response : URLResponse?, responseData : Data?,
         error : Error?,
         tags : [String : String])
    {
        self.requestStartedEvent = startEvent
        super.init(tags: tags)
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
            
            if let error = self.error {
                responseDict["error"] = error.localizedDescription
            }
        }

        let dataDict = ret["data"] as! NSMutableDictionary
        dataDict["response"] = responseDict
        ret["type"] = "REQUEST"
        ret["timestamp"] = timestampAsUTCString()
        ret["id"] = self.id
        ret["startId"] = self.requestStartedEvent.id
        ret["tags"] = self.tags

        return ret
    }
}

class MessageLogEvent : LogEvent {
    var message : String = ""
    
    init(message : String, tags : [String : String]) {
        super.init(tags: tags)
        self.message = message
    }
    
    override func toDictionary() -> NSDictionary {
        return [
            "type" : "LOG",
            "id" : self.id,
            "timestamp" : timestampAsUTCString(),
            "data" : message,
            "tags" : self.tags
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
    
    fileprivate func Log(_ message : String, tags : [String : String] = [:]) {
        self.events.append(MessageLogEvent(message: message, tags : tags))
    }
    
    fileprivate func LogObject(_ object : NSDictionary, message : String = "", tags : [String : String] = [:]) {
        self.events.append(ObjectLogEvent(object: object, message: message, tags : tags))
    }

    // MARK: URLRequest convenience methods
    var pendingReqEvents = [URLRequest : RequestLogStartedEvent]()

    fileprivate func LogRequestStart(_ request : URLRequest, tags : [String : String] = [:]) {
        let event = RequestLogStartedEvent(request: request, tags : tags)
        self.events.append(event)
        pendingReqEvents[request] = event
    }
    
    fileprivate func LogRequestFinished(_ request : URLRequest,
                                        response : URLResponse?,
                                        data : Data?,
                                        error : Error?,
                                        tags : [String : String])
    {
        if let startEvent = pendingReqEvents[request] {
            let event = RequestLogEvent(startEvent: startEvent, response: response, responseData: data, error: error, tags : tags)
            self.events.append(event)
            pendingReqEvents.removeValue(forKey: request)
        }
    }

    // Convenience static methods
    static open func Log(_ message : String, tags : [String : String] = [:]) {
        self.instance?.Log(message, tags : tags)
    }
    static open func LogRequestStart(_ request : URLRequest, tags : [String : String] = [:]) {
        self.instance?.LogRequestStart(request, tags: tags)
    }
    
    static open func LogRequestFinished(_ request : URLRequest,
                                        response : URLResponse?,
                                        data : Data?,
                                        error : Error?,
                                        tags : [String : String])
    {
        self.instance?.LogRequestFinished(request, response: response, data: data, error: error, tags: tags)
    }

    static open func LogObject(_ object : NSDictionary, message : String = "", tags : [String : String] = [:]) {
        self.instance?.LogObject(object, message : message, tags : tags)
    }
    
    static var Events : [LogEvent] {
        return self.instance?.events ?? []
    }
}
