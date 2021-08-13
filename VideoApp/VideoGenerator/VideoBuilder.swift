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
    
}
