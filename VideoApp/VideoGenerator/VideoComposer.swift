//
//  VideoComposer.swift
//  VideoApp
//
//  Created by Duy Truong on 11/07/2021.
//

import AVFoundation

class VideoComposer {
    
    private let video: AVURLAsset
    private let audio: AVURLAsset
    
    private let videoTrackId = CMPersistentTrackID(1)
    private let audioTrackId = CMPersistentTrackID(2)
    
    private let composition = AVMutableComposition()
    
    init(video: AVURLAsset, audio: AVURLAsset) {
        self.video = video
        self.audio = audio
    }
    
    func compose() {
        // Add track
        guard
            let videoCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: self.videoTrackId),
            let audioCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: self.audioTrackId)
        else {
            return
        }
        
        // Add video
        let timeRange = CMTimeRange(start: CMTime.zero, end: video.duration)
        if let videoTrack = video.tracks(withMediaType: .video).first {
            try? videoCompositionTrack.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
        }
        
        // Add music
        if video.duration.seconds < audio.duration.seconds {
            let timeRange = CMTimeRange(start: CMTime.zero, end: video.duration)
            if let audioTrack = audio.tracks(withMediaType: .audio).first {
                try? audioCompositionTrack.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)
            }
        } else {
            // TODO
        }
        
        // Merge
        let outputURL = FileManager.generateOutputURL(prefix: "video-merge-")
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.outputFileType = .mov
            exportSession.outputURL = outputURL
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.exportAsynchronously {
                print("Export status:", exportSession.status == .completed, outputURL)
            }
        }
    }
}
