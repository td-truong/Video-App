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
    
    static let imageScaleFactor = 1.25
    
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
    
    private lazy var playerLayer: AVPlayerLayer = {
        let playerLayer = AVPlayerLayer(player: videosPlayer)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        return playerLayer
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var imageAnimation: CABasicAnimation =  {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = QueuePlayerController.imageScaleFactor
        animation.delegate = self
        return animation
    }()
    
    private let disposeBag = DisposeBag()
    
    private let items: Observable<[QueuePlayerItem]>
    private let videosPlayer: AVQueuePlayer
    private let audioPlayer: AVPlayer
    
    private let videoItemIndex = BehaviorSubject<Int>(value: 0)
    private let currentItemTime = BehaviorSubject<Double>(value: 0)
    private let imageAnimationDidEnd = PublishSubject<Void>()
    
    var autoPlay = true
    
    private var totalLength: Observable<Double> {
        return items.map { items in
            items.reduce(0) { $0 + $1.length }
        }
    }
    
    private var videoTimeObserverToken: Any?
    private var imageTimeSubscriptions: [Disposable] = []
    
    init(items: [QueuePlayerItem], audioItem: AVPlayerItem?) {
        self.items = Observable.just(items)
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
        title = "Video"
        view.backgroundColor = .black
        
        view.layer.addSublayer(playerLayer)
        
        view.addSubview(imageView)
        view.addSubview(progressSlider)
        view.addSubview(maximumSliderLabel)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            progressSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            progressSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            progressSlider.heightAnchor.constraint(equalToConstant: 30),
            progressSlider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(view.bounds.height / 5)),
            maximumSliderLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),
            maximumSliderLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor)
        ])
    }
    
    private func setupSubscriptions() {
        let videoItem = videoItemIndex
            .distinctUntilChanged()
            .withLatestFrom(items) { (index: $0, items: $1) }
            .map { (index, items) in items[index] }
            .share()
            
        videoItem
            .subscribe(onNext: { [weak self] item in
                if let item = item as? VideoPlayerItem {
                    self?.videosPlayer.advanceToNextItem()
                    self?.videosPlayer.insert(item.item, after: nil)
                } else if let item = item as? ImagePlayerItem {
                    // TODO
                }
            })
            .disposed(by: disposeBag)
        
        videoItem
            .map { $0 is VideoPlayerItem }
            .map { !$0 }
            .asDriver(onErrorJustReturn: true)
            .drive(playerLayer.rx.isHidden)
            .disposed(by: disposeBag)
        
        videoItem
            .map { $0 is ImagePlayerItem }
            .map { !$0 }
            .asDriver(onErrorJustReturn: true)
            .drive(imageView.rx.isHidden)
            .disposed(by: disposeBag)
        
        Observable<Void>
            .merge(
                NotificationCenter.default.rx
                    .notification(.AVPlayerItemDidPlayToEndTime)
                    .map { _ in () },
                imageAnimationDidEnd
            )
            .withLatestFrom(videoItemIndex)
            .withLatestFrom(items) { (index: $0, items: $1) }
            .filter { $0 < $1.count - 1 }
            .map { (index: $0 + 1, items: $1) }
            .map { index, items in (index, items[index]) }
            .subscribe(onNext: { [weak self] index, item in
                if let videoItem = item as? VideoPlayerItem {
                    videoItem.seekTo(seconds: 0)
                    self?.videosPlayer.play()
                    self?.videoItemIndex.onNext(index)
                } else if let imageItem = item as? ImagePlayerItem {
                    self?.videosPlayer.pause()
                    self?.videoItemIndex.onNext(index)
                    self?.animateImage(imageItem, startAt: 0)
                }
            })
            .disposed(by: disposeBag)
        
        videoTimeObserverToken = videosPlayer
            .addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 30), queue: .main) { [weak self] time in
                self?.currentItemTime.onNext(time.seconds)
            }
        
        let playerTime = currentItemTime
            .debug("playerTime")
            .withLatestFrom(items) { (time: $0, items: $1) }
            .compactMap { [weak self] time, items -> Double? in
                guard let videoItemIndex = try? self?.videoItemIndex.value() else { return nil }
                
                var totalLengthBeforeCurrentItem = 0.0
                for index in 0..<videoItemIndex {
                    totalLengthBeforeCurrentItem += items[index].length
                }
                let playedLength = totalLengthBeforeCurrentItem + time
                return playedLength
            }
            .share()
        
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
 
        playerTime
            .withLatestFrom(totalLength) { playedLength, totalLength in Float(playedLength / totalLength) }
            .withLatestFrom(progressSliderSliding) { (progress: $0, sliding: $1) }
            .filter { !$0.sliding }
            .map { time, _ in time }
            .asDriver(onErrorJustReturn: 0.0)
            .drive(progressSlider.rx.value)
            .disposed(by: disposeBag)
        
        playerTime
            .withLatestFrom(totalLength) { playedLength, totalLength in
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
            .withLatestFrom(items) { (playedLength: $0, items: $1) }
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
                if let videoItem = seekItem as? VideoPlayerItem {
                    videoItem.seekTo(seconds: seekItemSeconds)
                    self?.videosPlayer.play()
                    self?.videoItemIndex.onNext(seekItemIndex)
                } else if let imageItem = seekItem as? ImagePlayerItem {
                    self?.videosPlayer.pause()
                    self?.videoItemIndex.onNext(seekItemIndex)
                    self?.animateImage(imageItem, startAt: seekItemSeconds)
                }
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
    
    private func animateImage(_ item: ImagePlayerItem, startAt: Double = 0) {
        removeImageAnimation()
        self.imageView.image = item.image
        
        imageAnimation.duration = item.length - startAt
        imageAnimation.fromValue = (startAt / item.length)
            * (QueuePlayerController.imageScaleFactor - 1) + 1
        imageView.layer.add(imageAnimation, forKey: nil)
        
        if startAt == 0 {
//            currentItemTime.onNext(0)
        }
        
//        if item.length <= ceil(startAt) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(1000 * (item.length - startAt)))) {
//                self.currentItemTime.onNext(item.length)
//            }
//        } else {
//            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(1000 * (ceil(startAt) - startAt)))) {
//                var playedLength = ceil(startAt)
//                ///Timer
//                while playedLength < item.length {
//                    self.currentItemTime.onNext(playedLength)
//                    playedLength += 1
//                }
//                playedLength -= 1
//                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(1000 * (item.length - playedLength)))) {
//                    self.currentItemTime.onNext(item.length)
//                }
//            }
//        }
        
        if item.length <= ceil(startAt) {
            let subscription = Observable.just(item.length)
                .delay(.milliseconds(Int(1000 * (item.length - startAt))), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] length in
                    self?.currentItemTime.onNext(length)
                })
            imageTimeSubscriptions.append(subscription)
        } else {
            let subscription = Observable<Int>
                .interval(.seconds(1), scheduler: MainScheduler.instance)
                .delay(.milliseconds(Int(1000 * (ceil(startAt) - startAt))), scheduler: MainScheduler.instance)
                .startWith(Int(ceil(startAt)))
                .take(Int(floor(item.length) - ceil(startAt)) + 1)
                .subscribe(onNext: { [weak self] element in
                    self?.currentItemTime.onNext(Double(Int(ceil(startAt)) + element + 1))
                }, onCompleted: { [weak self] in
                    guard item.length > floor(item.length) else { return }
                    let subscription = Observable.just(item.length)
                        .delay(.milliseconds(Int(1000 * (item.length - floor(item.length)))), scheduler: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] length in
                            self?.currentItemTime.onNext(length)
                        })
                    self?.imageTimeSubscriptions.append(subscription)
                })
            imageTimeSubscriptions.append(subscription)
        }
        
//        let secondsToNextTimeEmitted = min(item.length, ceil(startAt)) - startAt
//        let timeEmittedTimes = item.length > ceil(startAt)
//            ? lround(floor(item.length) - ceil(startAt)) + 1
//            : 0
//        Observable<Int>
//            .interval(.seconds(1), scheduler: MainScheduler.instance)
//            //            .startWith(Int(ceil(startAt)))
//            .startWith(0)
//            .delay(.milliseconds(Int(1000 * secondsToNextTimeEmitted)), scheduler: MainScheduler.instance)
//            .take(timeEmittedTimes)
//            .subscribe(onNext: { [weak self] element in
//                self?.currentItemTime.onNext(Double(Int(ceil(startAt)) + element + 1))
//            }, onCompleted: { [weak self] in
//                let after = item.length > ceil(startAt) ? item.length - ceil(startAt) : item.length - startAt
//                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(1000 * after))) {
//                    self?.currentItemTime.onNext(item.length)
//                }
//            })
    }
    
    private func removeImageAnimation() {
        self.imageView.layer.removeAllAnimations()
        imageTimeSubscriptions.forEach { $0.dispose() }
        imageTimeSubscriptions.removeAll()
    }
    
    private static func convertSecondsToMinutesAndSeconds(_ seconds: Double) -> String {
        let seconds = lround(seconds)
        let s = seconds % 60
        let m = seconds / 60
        return "\(String(format: "%02d", m)):\(String(format: "%02d", s))"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let token = videoTimeObserverToken {
            videosPlayer.removeTimeObserver(token)
        }
        imageTimeSubscriptions.forEach { $0.dispose() }
        imageAnimation.delegate = nil
    }
    
    deinit {
        print("✅ \(String(describing: type(of: self))) deinit!")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension QueuePlayerController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        imageAnimationDidEnd.onNext(())
        removeImageAnimation()
    }
}
