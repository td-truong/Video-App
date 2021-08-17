//
//  VideoBuilder.swift
//  VideoApp
//
//  Created by Duy Truong on 13/08/2021.
//

import UIKit
import AVFoundation

public typealias VideoCompletion = (URL?) -> Void

enum VideoConfigs {
    static var size = CGSize(width: 1080, height: 1920)
    static var contentMode: UIView.ContentMode = .scaleAspectFill
    static var animationEnabled = true
    static var animationFramesPerSecond = 20
    static var animationOffsetPerSecond: CGFloat = 15
}

public class VideoBuilder {
    
    private var images: [UIImage] = []
    private var audio: AVURLAsset?
    private var imageDuration: CMTime {
        guard let audio = audio else { return .zero }
        return CMTime(seconds: 3, preferredTimescale: audio.duration.timescale)
    }
    
    private var videoCombinedURL: URL? {
        didSet {
            if videoCombinedURL != nil, let mergeAudioHandler = mergeAudioHandler {
                _mergeAudio(completion: mergeAudioHandler)
            }
        }
    }
    
    private var mergeAudioHandler: VideoCompletion?
    
    public func addImages(_ images: [UIImage]) -> Self {
        self.images.append(contentsOf: images)
        return self
    }
    
    public func setAudio(withURL url: URL) -> Self {
        audio = AVURLAsset(url: url)
        return self
    }
    
    public func generateVideoFromImages(completion: (VideoCompletion)? = nil) -> Self {
        print(Date(), "Start generateVideoFromImages")
        guard !images.isEmpty else { completion?(nil); return self }
        createOutputDirectory()
        resizeImages()
        _generateVideoFromImages(completion: completion)
        return self
    }
    
    public func mergeAudio(completion: (VideoCompletion)? = nil) {
        guard audio != nil else { completion?(nil); return }
        mergeAudioHandler = completion
    }
    
    private func createOutputDirectory() {
        let outputDirectory = Endpoints.mergeVideoDirectory
        if FileManager.default.fileExists(atPath: outputDirectory.path) {
            try? FileManager.default.removeItem(at: outputDirectory)
        }
        try? FileManager.default.createDirectory(at: outputDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
    
    private func resizeImages() {
        var updatedImages: [UIImage] = []
        for image in self.images {
            let view = UIView(frame: CGRect(origin: .zero, size: VideoConfigs.size))
            let imageView = UIImageView(image: image)
            imageView.frame = view.bounds
            imageView.contentMode = VideoConfigs.contentMode
            imageView.backgroundColor = .green
            view.addSubview(imageView)
            updatedImages.append(view.shotImage())
        }
        self.images = updatedImages
    }
    
    private func _generateVideoFromImages(completion: VideoCompletion?) {
        let videoCombinedURL = Endpoints.videoCombined
        VideoCombiner.shared.makeVideo(images: images, imageDuration: imageDuration, outputURL: videoCombinedURL) {
            print(Date(), "Finish generateVideoFromImages", videoCombinedURL)
            self.videoCombinedURL = videoCombinedURL
            completion?(videoCombinedURL)
        }
    }
    
    private func _mergeAudio(completion: (VideoCompletion)?) {
        print(Date(), "Start mergeAudio")
        guard let videoCombinedURL = videoCombinedURL,
              let audio = audio else { completion?(nil); return }
        let video = AVURLAsset(url: videoCombinedURL)
        VideoMerger(video: video, audio: audio)
            .merge(outputURL: Endpoints.videoMerged) { url in
                print(Date(), "Finish mergeAudio", url)
                completion?(url)
            }
    }
    
    public func cropVideoWithoutAudio(_ video: AVURLAsset) {
        print(Date(), "Start cropVideoWithoutAudio")
        let composition = AVMutableComposition()
        
        // Add track
        guard let videoCompositionTrack = composition
                .addMutableTrack(withMediaType: .video,
                                 preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return
        }
        
        // Add video to track
        let timeRange = CMTimeRange(start: CMTime.zero, duration: video.duration)
        guard let videoTrack = video.tracks(withMediaType: .video).first else {
            return
        }
        try? videoCompositionTrack.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
        
        // Delete old file
        let outputURL = Endpoints.videoCropped
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        // Export
        let videoCompositon = scaleAspectFillCroppedVideoComposition(
            ofVideoTrack: videoTrack,
            outputSize: VideoConfigs.size,
            duration: video.duration,
            videoCompositionTrack: videoCompositionTrack
        )
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.outputFileType = .mov
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.videoComposition = videoCompositon
        exportSession?.outputURL = outputURL
        
        exportSession?.exportAsynchronously(completionHandler: {
            if exportSession?.status == .completed {
                print(Date(), "outputURL", outputURL)
            } else if let error = exportSession?.error {
                print(Date(), error)
            }            
        })
    }
    
    private func scaleAspectFillCroppedVideoComposition(
        ofVideoTrack videoTrack: AVAssetTrack,
        outputSize: CGSize,
        duration: CMTime,
        videoCompositionTrack: AVMutableCompositionTrack)
    -> AVMutableVideoComposition {
        // Calculate the scaleAspectFill transform
        let naturalSize = videoTrack.naturalSize
        let naturalRatio = naturalSize.width / naturalSize.height
        let outputRatio = outputSize.width / outputSize.height

        let scaleFactor: CGFloat
        var translateDistance: (x: CGFloat, y: CGFloat) = (0, 0)
        if naturalRatio < outputRatio {
            scaleFactor = outputSize.width / naturalSize.width
            translateDistance.y = -(scaleFactor * naturalSize.height - outputSize.height) / 2 / scaleFactor
        } else {
            scaleFactor = outputSize.height / naturalSize.height
            translateDistance.x = -(scaleFactor * naturalSize.width - outputSize.width) / 2 / scaleFactor
        }
        let transform = CGAffineTransform.identity
            .scaledBy(x: scaleFactor, y: scaleFactor)
            .translatedBy(x: translateDistance.x, y: translateDistance.y)
        
        // Init instructions
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        layerInstruction.setTransform(transform, at: CMTime.zero)
        
        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRange(start: CMTime.zero, duration: duration)
        mainInstructions.layerInstructions = [layerInstruction]
        
        // Init videoCompositon
        let videoCompositon = AVMutableVideoComposition()
        videoCompositon.renderSize = outputSize
        videoCompositon.instructions = [mainInstructions]
        videoCompositon.frameDuration = CMTime(value: 1, timescale: 30) // 30FPS
        
        return videoCompositon
    }
    
}
