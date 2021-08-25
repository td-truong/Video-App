//
//  QueuePlayerItem.swift
//  VideoApp
//
//  Created by Duy Truong on 23/08/2021.
//

import AVFoundation
import UIKit

protocol QueuePlayerItem {
    var length: Double { get }
}

struct VideoPlayerItem: QueuePlayerItem {
    let item: AVPlayerItem
    let length: Double

    private var assetLength: Double {
        return item.asset.duration.seconds
    }
    
    private var startAt: Double {
        return (assetLength - length) / 2
    }
    
    private var endAt: Double {
        return startAt + length
    }
    
    private var timescale: CMTimeScale {
        item.asset.duration.timescale
    }
    
    private var startTime: CMTime {
        CMTime(seconds: startAt, preferredTimescale: timescale)
    }
    
    private var endTime: CMTime {
        CMTime(seconds: endAt, preferredTimescale: timescale)
    }
    
    init(item: AVPlayerItem, length: Double) {
        self.item = item
        self.length = min(length, item.asset.duration.seconds)
    }
    
    /// Call every item starts playing
    func seekToStartAt() {
        item.seek(to: startTime, completionHandler: nil)
    }
    
    func seekTo(seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: timescale)
        item.seek(to: time, completionHandler: nil)
    }
    
    /// Call 1 time at first
    func setEndAt() {
        item.forwardPlaybackEndTime = endTime
    }
}

struct ImagePlayerItem: QueuePlayerItem {
    let image: UIImage
    let length: Double
}
