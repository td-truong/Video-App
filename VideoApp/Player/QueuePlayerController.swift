//
//  QueuePlayerController.swift
//  VideoApp
//
//  Created by Duy Truong on 18/08/2021.
//

import UIKit
import AVFoundation

class QueuePlayerController: UIViewController {
    
    private let videosPlayer: AVQueuePlayer
    private let audioPlayer: AVPlayer
    
    private let videoItems: [QueuePlayerItem]
    
    var autoPlay = true
    
    private var itemIndex = 0
    private var timer: Timer?
    
    init(videoItems: [QueuePlayerItem], audioItem: AVPlayerItem?) {
        self.videoItems = videoItems
        self.videosPlayer = AVQueuePlayer(playerItem: videoItems.first?.item)
        self.audioPlayer = AVPlayer(playerItem: audioItem)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupPlayers()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLoopItems(_:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            print(self.videosPlayer.currentTime().seconds)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        timer?.invalidate()
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        let playerLayer = AVPlayerLayer(player: videosPlayer)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
    }
    
    private func setupPlayers() {
        for item in videoItems {
            item.seekToStartAt()
            item.setEndAt()
        }
        
        videosPlayer.isMuted = true
        
        if autoPlay {
            videosPlayer.play()
            audioPlayer.play()
        }
    }
    
    @objc private func handleLoopItems(_ notification: Notification) {
        let nextIndex = (itemIndex == videoItems.count - 1) ? 0 : itemIndex + 1
        let nextItem = videoItems[nextIndex]
        
        nextItem.seekToStartAt()
        videosPlayer.advanceToNextItem()
        videosPlayer.insert(nextItem.item, after: nil)
        
        itemIndex = nextIndex
    }
    
    deinit {
        print("Deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
