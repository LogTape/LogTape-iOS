//
//  LogTapeVideoRecorder.swift
//  Pods
//
//  Created by Dan Nilsson on 2017-06-13.
//
//

import Foundation
import AVKit
import AVFoundation

class LogTapeVideoWriter : NSObject {
    var path : String? = nil
    var writerInput : AVAssetWriterInput? = nil
    var adaptor : AVAssetWriterInputPixelBufferAdaptor? = nil
    var curFrame = 0
    var onCompleted : ((_ path : String?) -> ())? = nil
    var videoWriter : AVAssetWriter? = nil
    var videoSize = CGSize.zero
    var frames : [UIImage]
    
    init(onCompleted : @escaping ((_ path : String?) -> ()),
         size : CGSize,
         frames : [UIImage]) {
        self.onCompleted = onCompleted
        self.frames = frames
        self.videoSize = size
    }
    
    func startWriting() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = documentsPath + "/out.mp4"
        let url = URL(fileURLWithPath: path)
        self.path = path
        let fileManager = FileManager.default
        
        do {
            if fileManager.isReadableFile(atPath: path) {
                try fileManager.removeItem(atPath: path)
            }
            
            let videoWriter = try AVAssetWriter(outputURL: url, fileType: "public.mpeg-4")
            
            let videoSettings : [String : AnyObject] = [
                AVVideoCodecKey : AVVideoCodecH264 as AnyObject,
                AVVideoWidthKey : videoSize.width as AnyObject,
                AVVideoHeightKey : videoSize.height as AnyObject
            ]
            
            let writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: nil)
            videoWriter.add(writerInput)
            videoWriter.startWriting()
            videoWriter.startSession(atSourceTime: kCMTimeZero)
            
            self.videoWriter = videoWriter
            self.writerInput = writerInput
            self.adaptor = adaptor
            
            writerInput.addObserver(self, forKeyPath: "readyForMoreMediaData", options: [.initial, .new], context: nil)
        } catch _ {
            onCompleted?(nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async { () -> Void in
            guard let writerInput = self.writerInput, let adaptor = self.adaptor, let videoWriter = self.videoWriter , self.frames.count > 0 else
            {
                return
            }
            
            while writerInput.isReadyForMoreMediaData {
                let frame = self.frames.removeFirst()
                
                var pixelbuffer: CVPixelBuffer? = nil
                
                CVPixelBufferCreate(kCFAllocatorDefault, Int(self.videoSize.width), Int(self.videoSize.height), kCVPixelFormatType_32ARGB, nil, &pixelbuffer)
                CVPixelBufferLockBaseAddress(pixelbuffer!, CVPixelBufferLockFlags(rawValue:0))
                
                let colorspace = CGColorSpaceCreateDeviceRGB()
                let pixelBufferBase = CVPixelBufferGetBaseAddress(pixelbuffer!)
                let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelbuffer!)
                
                guard let bitmapContext = CGContext(data: pixelBufferBase, width: Int(self.videoSize.width), height: Int(self.videoSize.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorspace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else
                {
                    print("Failed to create bitmap context")
                    DispatchQueue.main.async {
                        self.onCompleted?(nil)
                    }
                    return
                }
                
                bitmapContext.draw(frame.cgImage!, in: CGRect(x: 0, y: 0, width: self.videoSize.width, height: self.videoSize.height))
                
                let time = CMTimeMake(10 * Int64(self.curFrame * LogTapeVideoRecorder.FPSPeriod), 600)
                
                if let pixelbuffer = pixelbuffer {
                    adaptor.append(pixelbuffer, withPresentationTime: time)
                }

                self.curFrame += 1
                
                if self.frames.count == 0 {
                    writerInput.markAsFinished()
                    writerInput.removeObserver(self, forKeyPath: "readyForMoreMediaData")
                    
                    videoWriter.finishWriting {
                        DispatchQueue.main.async {
                            self.onCompleted?(self.path)
                        }
                    }
                    break
                }
            }
            
        }
    }
}

class LogTapeVideoRecorder : NSObject {
    var frames = [UIImage]()
    
    static let MaxNumFrames = 600
    var captureFrameTimer : Foundation.Timer? = nil
    static let FPSPeriod = 4
    static var CaptureInterval : TimeInterval {
        return 1.0 / (60.0 / TimeInterval(LogTapeVideoRecorder.FPSPeriod))
    }
    static let TouchStrokeColor = UIColor.red
    static let TouchFillColor = UIColor.red.withAlphaComponent(0.4)

    static let TouchCircleSize = CGFloat(30.0)
    
    func start() {
        self.frames = []
        self.captureFrameTimer = Foundation.Timer(timeInterval: LogTapeVideoRecorder.CaptureInterval,
                                                  target: self,
                                                  selector: #selector(LogTapeVideoRecorder.captureFrame),
                                                  userInfo: nil,
                                                  repeats: true)
        
        RunLoop.current.add(captureFrameTimer!, forMode: RunLoopMode.commonModes)

    }
    
    func clear() {
        self.stop()
        self.frames = []
    }
    
    func stop() {        
        self.captureFrameTimer?.invalidate()
        self.captureFrameTimer = nil
    }
    
    deinit {
        self.captureFrameTimer?.invalidate()
        self.captureFrameTimer = nil
    }
    
    func handleTouch(_ touch : UITouch) {
        guard let window = touch.window,
            let lastFrame = self.frames.last else
        {
            return
        }
        
        // On each touch grab the latest captured frame and overlay the touch location
        // using a circle
        let screenSize = UIScreen.main.bounds.size
        let frameSize = self.frameSizeFromScreenSize(screenSize)
        let frameBounds = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        UIGraphicsBeginImageContextWithOptions(frameSize, false, 1.0)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        
        let touchLocation = touch.location(in: window)
        let ratio = screenSize.width / frameSize.width
        
        let locationInFrame = CGPoint(x : touchLocation.x / ratio, y : touchLocation.y / ratio)
        
        context.setStrokeColor(UIColor.black.cgColor)
        lastFrame.draw(in: frameBounds)
        context.setStrokeColor(LogTapeVideoRecorder.TouchStrokeColor.cgColor)
        context.setFillColor(LogTapeVideoRecorder.TouchFillColor.cgColor)
        
        
        let touchCircleOffset = LogTapeVideoRecorder.TouchCircleSize / 2.0
        
        let touchCircleRect = CGRect(x: locationInFrame.x - touchCircleOffset,
                                     y: locationInFrame.y - touchCircleOffset,
                                     width: LogTapeVideoRecorder.TouchCircleSize,
                                     height: LogTapeVideoRecorder.TouchCircleSize)
        

        context.fillEllipse(in: touchCircleRect)
        context.strokeEllipse(in: touchCircleRect)

        let overlaidFrame = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        
        self.frames.removeLast()
        self.frames.append(overlaidFrame!)
    }
    
    func captureFrame() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let frameSize = self.frameSizeFromScreenSize(window.bounds.size)
        let frameBounds = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height);
        
        UIGraphicsBeginImageContextWithOptions(frameSize, false, 1.0)
        window.drawHierarchy(in: frameBounds, afterScreenUpdates: false)
        
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            self.frames.append(image)
        }
        
        UIGraphicsEndImageContext()
        
        if self.frames.count > LogTapeVideoRecorder.MaxNumFrames {
            self.frames.remove(at: 0)
        }
    }
    
    func frameSizeFromScreenSize(_ screenSize : CGSize) -> CGSize {
        let frameWidth = floor(min(screenSize.width, 512) / 16.0) * 16.0
        let aspectRatio = screenSize.width / frameWidth
        let frameHeight = ceil(screenSize.height / aspectRatio)
        return CGSize(width: frameWidth, height: frameHeight)
    }
    
    var writer : LogTapeVideoWriter? = nil
    
    func writeToFile(_ onCompleted : @escaping ((_ path : String?) -> ())) {
        self.captureFrameTimer?.invalidate()
        self.captureFrameTimer = nil
        
        self.writer = LogTapeVideoWriter(onCompleted : onCompleted,
                                         size : self.frameSizeFromScreenSize(UIScreen.main.bounds.size),
                                         frames : self.frames)
        self.writer?.startWriting()
        self.frames = []
    }
    
    func duration() -> TimeInterval {
        return LogTapeVideoRecorder.CaptureInterval * TimeInterval(self.frames.count);
    }
}
