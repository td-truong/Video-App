//
//  QueuePlayerController.swift
//  VideoApp
//
//  Created by Duy Truong on 18/08/2021.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

class QueuePlayerController: UIViewController {
    
    private lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .white
        return slider
    }()
    
    private lazy var maximumSliderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00 / 00:00"
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()
    
    private let disposeBag = DisposeBag()
    
    private let videoItems: Observable<[QueuePlayerItem]>
    private let videosPlayer: AVQueuePlayer
    private let audioPlayer: AVPlayer
    
    private let videoItemIndex = BehaviorSubject<Int>(value: 0)
    private let playerTime = PublishSubject<CMTime>()
    
    var autoPlay = true
    
    private var totalLength: Observable<Double> {
        return videoItems.map { items in
            items.reduce(0) { $0 + $1.length }
        }
    }
    
    private var timeObserverToken: Any?
    
    init(videoItems: [QueuePlayerItem], audioItem: AVPlayerItem?) {
        self.videoItems = Observable.just(videoItems)
        self.videosPlayer = AVQueuePlayer()
        self.audioPlayer = AVPlayer(playerItem: audioItem)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupSubscriptions()
        setupPlayers()
    }
    
    private func setupViews() {
        view.backgroundColor = .black
        
        let playerLayer = AVPlayerLayer(player: videosPlayer)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        
        view.addSubview(progressSlider)
        view.addSubview(maximumSliderLabel)
        NSLayoutConstraint.activate([
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            progressSlider.heightAnchor.constraint(equalToConstant: 30),
            progressSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.bounds.height / 5)),
            maximumSliderLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),
            maximumSliderLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor)
        ])
    }
    
    private func setupSubscriptions() {
        videoItemIndex
            .distinctUntilChanged()
            .withLatestFrom(videoItems) { (index: $0, items: $1) }
            .subscribe(onNext: { [weak self] index, items in
                let item = items[index]
                self?.videosPlayer.advanceToNextItem()
                self?.videosPlayer.insert(item.item, after: nil)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(.AVPlayerItemDidPlayToEndTime)
            .withLatestFrom(videoItemIndex)
            .withLatestFrom(videoItems) { (index: $0, items: $1) }
            .filter { $0 < $1.count - 1 }
            .map { (index: $0 + 1, items: $1) }
            .subscribe(onNext: { [weak self] index, items in
                let item = items[index]
                item.seekTo(seconds: 0) // TODO
                self?.videoItemIndex.onNext(index)
            })
            .disposed(by: disposeBag)
        
        timeObserverToken = videosPlayer
            .addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 30), queue: .main) { [weak self] time in
                self?.playerTime.onNext(time)
            }
        
        let progressSliderSliding = Observable<Bool>
            .merge([
                progressSlider.rx
                    .controlEvent(.touchDown)
                    .map { _ in true },
                progressSlider.rx
                    .controlEvent([.touchUpInside, .touchUpOutside])
                    .map { _ in false }
            ])
            .startWith(false)
        
        let playerProgress = playerTime
            .withLatestFrom(videoItems) { (time: $0, items: $1) }
            .withLatestFrom(totalLength) { (time: $0.time, items: $0.items, totalLength: $1) }
            .compactMap { [weak self] time, items, totalLength -> Float? in
                guard let videoItemIndex = try? self?.videoItemIndex.value() else { return nil }
                
                var totalLengthBeforeCurrentItem = 0.0
                for index in 0..<videoItemIndex {
                    totalLengthBeforeCurrentItem += items[index].length
                }
                let playedLength = totalLengthBeforeCurrentItem + time.seconds
                
                let progress = playedLength / totalLength
                return Float(progress)
            }
            .share()
        
        playerProgress
            .withLatestFrom(progressSliderSliding) { (time: $0, sliding: $1) }
            .filter { !$0.sliding }
            .map { time, _ in time }
            .asDriver(onErrorJustReturn: 0.0)
            .drive(progressSlider.rx.value)
            .disposed(by: disposeBag)
        
        playerProgress
            .withLatestFrom(totalLength) { (progress: $0, totalLength: $1) }
            .map { (playedLength: Double($0) * $1, totalLength: $1) }
            .map { playedLength, totalLength in
                let playedText = Self.convertSecondsToMinutesAndSeconds(playedLength)
                let totalText = Self.convertSecondsToMinutesAndSeconds(totalLength)
                return "\(playedText) / \(totalText)"
            }
            .asDriver(onErrorJustReturn: "00:00")
            .drive(maximumSliderLabel.rx.text)
            .disposed(by: disposeBag)        
        
        progressSlider.rx.value
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .withLatestFrom(totalLength) { (value: $0, totalLength: $1) }
            .map { Double($0) * $1 }
            .withLatestFrom(videoItems) { (playedLength: $0, items: $1) }
            .subscribe(onNext: { [weak self] playedLength, items in
                var seekItemIndex = 0
                var seekItemSeconds = 0.0
                
                var totalLengthBeforeSeekItem = 0.0
                for (index, item) in items.enumerated() {
                    if totalLengthBeforeSeekItem + item.length > playedLength {
                        seekItemIndex = index
                        seekItemSeconds = playedLength - totalLengthBeforeSeekItem
                        break
                    } else {
                        totalLengthBeforeSeekItem += item.length
                    }
                }
                
                let seekItem = items[seekItemIndex]
                seekItem.seekTo(seconds: seekItemSeconds)
                self?.videoItemIndex.onNext(seekItemIndex)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupPlayers() {
//        videosPlayer.actionAtItemEnd = .pause // TODO: Item before last is paused now
        audioPlayer.isMuted = true
        
        if autoPlay {
            videosPlayer.play()
            audioPlayer.play()
        }
    }
    
    private static func convertSecondsToMinutesAndSeconds(_ seconds: Double) -> String {
        let seconds = Int(seconds)
        let s = seconds % 60
        let m = seconds / 60
        return "\(String(format: "%02d", m)):\(String(format: "%02d", s))"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = timeObserverToken {
            videosPlayer.removeTimeObserver(token)
        }
    }
    
    deinit {
        print("✅ \(String(describing: type(of: self))) deinit!")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

struct QueuePlayerItem {
    var item: AVPlayerItem
    var startAt: Double
    var endAt: Double
    
    var length: Double {
        //        return endAt - startAt
        return item.asset.duration.seconds // TODO
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
