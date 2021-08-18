//
//  VideoMerger.swift
//  VideoApp
//
//  Created by Duy Truong on 11/07/2021.
//

import AVFoundation

class VideoMerger {
    
    static let shared = VideoMerger()
    private init() {}
    
    func merge(video: AVURLAsset,
                      audio: AVURLAsset,
                      outputURL: URL,
                      completion: @escaping (URL) -> Void) {
        let (composition, _videoCompositionTrack, _audioCompositionTrack) = initCompositions()
        guard let videoCompositionTrack = _videoCompositionTrack,
              let audioCompositionTrack = _audioCompositionTrack else {
            return
        }
        
        // Add video
        let timeRange = CMTimeRange(start: CMTime.zero, end: video.duration)
        if let videoTrack = video.tracks(withMediaType: .video).first {
            try? videoCompositionTrack.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
        }
        
        // Add music
        var insertTime = CMTime.zero
        while insertTime < video.duration {
            let timeRangeDuration = (insertTime + audio.duration < video.duration)
                ? audio.duration
                : video.duration - insertTime
            let timeRange = CMTimeRange(start: CMTime.zero, duration: timeRangeDuration)
            let audioTrack = audio.tracks(withMediaType: .audio)[0]
            try? audioCompositionTrack.insertTimeRange(timeRange, of: audioTrack, at: insertTime)
            
            insertTime += timeRangeDuration
        }
        
        // Merge
        ExportSessionHelper.export(asset: composition,
                                   outputURL: outputURL,
                                   onSuccess: {
                                    completion(outputURL)
                                   })
    }
    
    func merge(videos: [AVURLAsset],
               audio: AVURLAsset,
               transformDict: [AVURLAsset: CGAffineTransform],
               outputURL: URL,
               outputSize: CGSize,
               completion: @escaping (URL) -> Void) {
        let (composition, _videoCompositionTrack, _audioCompositionTrack) = initCompositions()
        guard let videoCompositionTrack = _videoCompositionTrack,
              let audioCompositionTrack = _audioCompositionTrack else { return }
        
        // Add videos
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)

        var insertTime = CMTime.zero
        for video in videos {
//            let timeRange = CMTimeRange(start: CMTime.zero, duration: video.duration)
            let timeRange = CMTimeRange(start: CMTime(seconds: 3, preferredTimescale: video.duration.timescale), duration: CMTime(seconds: 6, preferredTimescale: video.duration.timescale)) // TODO
            if let videoTrack = video.tracks(withMediaType: .video).first {
                try? videoCompositionTrack.insertTimeRange(timeRange, of: videoTrack, at: insertTime)
                if let transform = transformDict[video] {
                    layerInstruction.setTransform(transform, at: insertTime)
                }
            }
            
            insertTime += CMTime(seconds: 6, preferredTimescale: video.duration.timescale)
        }
        
        let totalDuration = insertTime
        
        // Add audio
        insertTime = CMTime.zero
        while insertTime < totalDuration {
            let timeRangeDuration = (insertTime + audio.duration < totalDuration)
                ? audio.duration
                : totalDuration - insertTime
            let timeRange = CMTimeRange(start: CMTime.zero, duration: timeRangeDuration)
            let audioTrack = audio.tracks(withMediaType: .audio)[0]
            try? audioCompositionTrack.insertTimeRange(timeRange, of: audioTrack, at: insertTime)
            
            insertTime += timeRangeDuration
        }
        
        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRange(start: CMTime.zero, duration: totalDuration)
        mainInstructions.layerInstructions = [layerInstruction]
        
        let videoCompositon = AVMutableVideoComposition()
        videoCompositon.renderSize = outputSize
        videoCompositon.instructions = [mainInstructions]
        videoCompositon.frameDuration = CMTime(value: 1, timescale: 30)
        
        print(Date(), "Start export")
        ExportSessionHelper.export(asset: composition,
                                   outputFileType: .mp4,
                                   outputURL: outputURL,
                                   videoComposition: videoCompositon) {
            completion(outputURL)
        } onError: { error in
            print("Error", error)
        }

    }
    
//    func mergeVideos(videos: [AVURLAsset],
//                     outputURL: URL,
//                     completion: @escaping (URL) -> Void) {
//        let composition = AVMutableComposition()
//        guard let videoCompositionTrack = composition
//                .addMutableTrack(withMediaType: .video,
//                                 preferredTrackID: kCMPersistentTrackID_Invalid) else {
//            return
//        }
//
//        var insertTime = CMTime.zero
//        for video in videos {
//            let timeRange = CMTimeRange(start: CMTime.zero, duration: video.duration)
//            let videoTrack = video.tracks(withMediaType: .video)[0]
//            try? videoCompositionTrack.insertTimeRange(timeRange, of: videoTrack, at: insertTime)
//
//            insertTime += video.duration)
//        }
//
//        print(Date(), "Start export")
//        ExportSessionHelper.export(asset: composition,
//                                   outputFileType: .mp4,
//                                   outputURL: outputURL) {
//            completion(outputURL)
//        } onError: { error in
//            print("Error", error)
//        }
//    }

    private func initCompositions() -> (main: AVMutableComposition,
                                        video: AVMutableCompositionTrack?,
                                        audio: AVMutableCompositionTrack?) {
        let composition = AVMutableComposition()

        // Add tracks
        let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        return (composition, videoCompositionTrack, audioCompositionTrack)
    }
    
}
