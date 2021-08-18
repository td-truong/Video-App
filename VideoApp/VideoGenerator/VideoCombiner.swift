//
//  VideoCombiner.swift
//  VideoApp
//
//  Created by Duy Truong on 13/08/2021.
//

import UIKit
import AVFoundation

class VideoCombiner {
    
    static let shared = VideoCombiner()
    private init() {}
    
    private let queue = DispatchQueue(label: "VideoCombiner")
    
    func makeVideo(images: [UIImage],
                   imageDuration: CMTime,
                   outputURL: URL,
                   completion: @escaping () -> Void) {
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else { return }
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: VideoConfigs.size.width,
            AVVideoHeightKey: VideoConfigs.size.height
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        
        let sourcePixelBufferAttributes: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                           sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        guard writer.canAdd(writerInput) else { return }
        writer.add(writerInput)
        
        guard writer.startWriting() else { return }
        writer.startSession(atSourceTime: .zero)
        
        writerInput.requestMediaDataWhenReady(on: self.queue) {
            var imageIndex = 0
            var presentationTime = CMTime.zero
            while writerInput.isReadyForMoreMediaData && imageIndex < images.count {
                let image = images[imageIndex]
                _ = self.appendPixelBuffer(for: adaptor,
                                           image: image,
                                           presentationTime: presentationTime,
                                           imageDuration: imageDuration)
                presentationTime += imageDuration
                imageIndex += 1
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                completion()
            }
        }
    }
    
    private func appendPixelBuffer(for adaptor: AVAssetWriterInputPixelBufferAdaptor,
                                   image: UIImage,
                                   presentationTime: CMTime,
                                   imageDuration: CMTime) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        var presentationTime = presentationTime
        
        let imageSeconds = Int(imageDuration.seconds)
        let animationFrameCount = VideoConfigs.animationEnabled
            ? VideoConfigs.animationFramesPerSecond * imageSeconds
            : 1
        let animationTime = imageDuration / Int32(animationFrameCount)
        let animationOffset = VideoConfigs.animationOffsetPerSecond * CGFloat(imageSeconds)
        
        for frameIndex in 0 ... animationFrameCount - 1 {
            let progress = Double(frameIndex) / Double(animationFrameCount)
            
            let appendSuccess = autoreleasepool { () -> Bool in
                let options: [String: Any] = [
                    kCVPixelBufferCGImageCompatibilityKey as String: true,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
                ]
                
                var pixelBuffer: CVPixelBuffer?
                
                let status = CVPixelBufferCreate(
                    kCFAllocatorDefault,
                    Int(VideoConfigs.size.width),
                    Int(VideoConfigs.size.height),
                    kCVPixelFormatType_32ARGB,
                    options as CFDictionary?,
                    &pixelBuffer
                )
                
                guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else { return false }
                fillPixelBuffer(for: pixelBuffer,
                                from: cgImage,
                                progress: progress,
                                animationOffset: animationOffset)
                
                let success = adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                presentationTime += animationTime
                return success
            }
            
            if !appendSuccess {
                return false
            }
        }
        
        return true
    }
    
    private func fillPixelBuffer(for pixelBuffer: CVPixelBuffer,
                                 from image: CGImage,
                                 progress: Double,
                                 animationOffset: CGFloat) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let (width, height) = (Int(VideoConfigs.size.width), Int(VideoConfigs.size.height))
        let bitsPerComponent = 8
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let space = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue
        
        let context = CGContext(data: data,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: space,
                                bitmapInfo: bitmapInfo)
        
        context?.interpolationQuality = .low
        
        draw(context: context,
             image: image,
             progress: progress,
             animationOffset: animationOffset)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))
    }
    
    private func draw(context: CGContext?,
                      image: CGImage,
                      progress: Double,
                      animationOffset: CGFloat) {
        let width = CGFloat(progress) * animationOffset + VideoConfigs.size.width
        let height = CGFloat(progress) * animationOffset + VideoConfigs.size.height
        
        let rect = CGRect(
            x: -(CGFloat(progress) * animationOffset) / 2,
            y: -(CGFloat(progress) * animationOffset) / 2,
            width: width,
            height: height
        )
        
        context?.draw(image, in: rect)
    }
}

