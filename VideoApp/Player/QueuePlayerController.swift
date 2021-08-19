//
//  QueuePlayerController.swift
//  VideoApp
//
//  Created by Duy Truong on 18/08/2021.
//

import UIKit
import AVFoundation

class QueuePlayerController: UIViewController {
    
    private(set) var player: AVQueuePlayer!
    var queuePlayerItems: [QueuePlayerItem] = [] {
        didSet {
            guard !queuePlayerItems.isEmpty else {
                return
            }
            
            let playerItems: [AVPlayerItem] = queuePlayerItems.map { queueItem in
                queueItem.seekToStartAt()
                queueItem.setEndAt()
                return queueItem.item
            }
            player = AVQueuePlayer(items: playerItems)
        }
    }
    
    private var itemIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLoopItems(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupViews() {
        guard let player = player else {
            return
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
    }
    
    @objc private func handleLoopItems(_ notification: Notification) {
        let nextIndex = (itemIndex == queuePlayerItems.count - 1) ? 0 : itemIndex + 1
        if player.items().count == 1 {
            let queueItem = queuePlayerItems[nextIndex]
            queueItem.seekToStartAt()
            player.advanceToNextItem()
            player.insert(queueItem.item, after: nil)
        }
        
        itemIndex = nextIndex
    }
    
}

struct QueuePlayerItem {
    var item: AVPlayerItem
    var startAt: TimeInterval
    var endAt: TimeInterval
    
    private var timescale: CMTimeScale {
        item.asset.duration.timescale
    }
    
    private var startTime: CMTime {
        CMTime(seconds: startAt, preferredTimescale: timescale)
    }
    
    private var endTime: CMTime {
        CMTime(seconds: endAt, preferredTimescale: timescale)
    }
    
    /// Call every item starts playing
    func seekToStartAt() {
        item.seek(to: startTime, completionHandler: nil)
    }
    
    /// Call 1 time at first
    func setEndAt() {
        item.forwardPlaybackEndTime = endTime
    }
    
}
