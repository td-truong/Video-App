//
//  VideoGenerator.swift
//  VideoApp
//
//  Created by Duy Truong on 06/07/2021.
//

import UIKit
import AVFoundation

class VideoGenerator {
    
    private var images: [UIImage]
    private let audio: AVURLAsset
    private let imageDuration: CMTime
    
    private let outputURL: URL = Endpoints.videoGen
    private let queue = DispatchQueue(label: "videoGeneratorQueue")
    
    private let defaultSize = CGSize(width: 1080, height: 1920)
    private let imageContentMode: UIView.ContentMode = .scaleAspectFill
    private let animationFramesPerSecond = 20
    private let animationOffsetPerSecond: CGFloat = 15
    
    private let completionHandler: (URL) -> Void
    
    init(images: [UIImage], audioURL: URL, completion: @escaping (URL) -> Void) {
        self.images = images
        self.audio = AVURLAsset(url: audioURL)
//        self.imageDuration = CMTimeMultiplyByRatio(self.audio.duration, multiplier: 1, divisor: Int32(self.images.count))
        self.imageDuration = CMTime(seconds: 3, preferredTimescale: self.audio.duration.timescale)
        self.completionHandler = completion
    }
    
    func process() {
        print(Date(), "Start merging")
        createOutputDirectory()
        updateImagesSize()
        makeVideo() {
            self.mergeAudio()
        }
    }
    
    private func createOutputDirectory() {
        let outputDirectory = Endpoints.mergeVideoDirectory
        if FileManager.default.fileExists(atPath: outputDirectory.path) {
            try? FileManager.default.removeItem(at: outputDirectory)
        }
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
        print("outputURL", outputURL)
    }
    
    private func updateImagesSize() {
        var updatedImages: [UIImage] = []
        for image in self.images {
            let view = UIView(frame: CGRect(origin: .zero, size: defaultSize))
            view.backgroundColor = .red
            let imageView = UIImageView(image: image)
            imageView.frame = view.bounds
            imageView.contentMode = self.imageContentMode
            imageView.backgroundColor = .green
            view.addSubview(imageView)
            updatedImages.append(view.shotImage())
        }
        self.images = updatedImages
    }
    
    private func makeVideo(completion: @escaping () -> Void) {
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else { return }
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: self.defaultSize.width,
            AVVideoHeightKey: self.defaultSize.height
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        
        let sourcePixelBufferAttributes: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        guard writer.canAdd(writerInput) else { return }
        writer.add(writerInput)
        
        guard writer.startWriting() else { return }
        writer.startSession(atSourceTime: .zero)
        
        writerInput.requestMediaDataWhenReady(on: self.queue) {
            var imageIndex = 0
            var presentationTime = CMTime.zero
            while writerInput.isReadyForMoreMediaData && imageIndex < self.images.count {
                let image = self.images[imageIndex]
                _ = self.appendPixelBuffer(for: adaptor, image: image, presentationTime: presentationTime)
                
                presentationTime = CMTimeAdd(presentationTime, self.imageDuration)
                imageIndex += 1
            }
            
            writerInput.markAsFinished()
            writer.finishWriting {
                print(Date(), "finished", self.outputURL)
                completion()
            }
        }
    }
    
    private func appendPixelBuffer(for adaptor: AVAssetWriterInputPixelBufferAdaptor, image: UIImage, presentationTime: CMTime) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        var presentationTime = presentationTime
        
        let imageSeconds = Int(self.imageDuration.seconds)
        let animationFrameCount = self.animationFramesPerSecond * imageSeconds
        let animationTime = CMTimeMultiplyByRatio(self.imageDuration, multiplier: 1, divisor: Int32(animationFrameCount))
        let animationOffset = self.animationOffsetPerSecond * CGFloat(imageSeconds)
        
        for frameIndex in 1 ... animationFrameCount {
            let progress = Double(frameIndex) / Double(animationFrameCount)
            
            let appendSuccess = autoreleasepool { () -> Bool in
                let options: [String: Any] = [
                    kCVPixelBufferCGImageCompatibilityKey as String: true,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
                ]

                var pixelBuffer: CVPixelBuffer?

                let status = CVPixelBufferCreate(
                    kCFAllocatorDefault,
                    Int(self.defaultSize.width),
                    Int(self.defaultSize.height),
                    kCVPixelFormatType_32ARGB,
                    options as CFDictionary?,
                    &pixelBuffer
                )

                guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else { return false }
                fillPixelBuffer(for: pixelBuffer, from: cgImage, progress: progress, animationOffset: animationOffset)

                let success = adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                presentationTime = CMTimeAdd(presentationTime, animationTime)
                return success
            }
            
            if !appendSuccess {
                return false
            }
        }
        
        return true
    }
    
    private func fillPixelBuffer(for pixelBuffer: CVPixelBuffer, from image: CGImage, progress: Double, animationOffset: CGFloat) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let (width, height) = (Int(self.defaultSize.width), Int(self.defaultSize.height))
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
        
        draw(context: context, image: image, progress: progress, animationOffset: animationOffset)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0))
    }
    
    private func draw(context: CGContext?, image: CGImage, progress: Double, animationOffset: CGFloat) {
        let width = CGFloat(progress) * animationOffset + defaultSize.width
        let height = CGFloat(progress) * animationOffset + defaultSize.height
        
        let rect = CGRect(
            x: -(CGFloat(progress) * animationOffset) / 2,
            y: -(CGFloat(progress) * animationOffset) / 2,
            width: width,
            height: height
        )
        
        context?.draw(image, in: rect)
    }
    
    private func mergeAudio() {
        let video = AVURLAsset(url: outputURL)
        VideoComposer(video: video, audio: audio)
            .compose(completion: completionHandler)
    }
    
}
