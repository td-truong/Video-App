//
//  ViewController.swift
//  VideoApp
//
//  Created by Duy Truong on 05/07/2021.
//

import AVKit
import MobileCoreServices

class ViewController: UIViewController {
    
    lazy var mergeImagesAndAudioButton = makeButton(title: "Merge images and audio",
                                                    action: #selector(mergeImagesAndAudio(_:)))
    
    lazy var mergeVideosAndAudioButton = makeButton(title: "Merge videos and audio",
                                                    action: #selector(mergeVideosAndAudio(_:)))
    
    lazy var mergeVideosAndAudioByImagePickerButton = makeButton(title: "Merge videos and audio by image picker",
                                                                 action: #selector(mergeVideosAndAudioByImagePicker(_:)))
    
    lazy var showFilteredPlayerButton = makeButton(title: "Show filter player",
                                                   action: #selector(showFilteredPlayer))
    
    lazy var showQueuePlayerButton = makeButton(title: "Show queue player",
                                                action: #selector(showQueuePlayer))
    
    let testMp4: URL = Bundle.main.url(forResource: "test", withExtension: "mp4")!
    let test2Mp4: URL = Bundle.main.url(forResource: "test2", withExtension: "mp4")!
    let soundMp3: URL = Bundle.main.url(forResource: "Sound", withExtension: "mp3")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    private func setupViews() {
        title = "Home"
        view.backgroundColor = .white
        
        let stackView = UIStackView(arrangedSubviews: [
            mergeImagesAndAudioButton,
            mergeVideosAndAudioButton,
            mergeVideosAndAudioByImagePickerButton,
            showFilteredPlayerButton,
            showQueuePlayerButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .equalSpacing
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    @objc private func mergeImagesAndAudio(_ button: UIButton) {
        showLoading()
        
        var images: [UIImage] = []
        for i in 0...3 {
            images.append(UIImage(named: "image\(i)")!)
        }
        
        //        VideoConfigs.animationEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            VideoBuilder()
                .addImages(images)
                .setAudio(withURL: self.soundMp3)
                .generateVideoFromImages()
                .mergeAudio { [weak self] url in
                    DispatchQueue.main.async {
                        self?.hideLoading()
                        
                        if let url = url, let self = self {
                            let playerVC = AVPlayerViewController()
                            playerVC.player = AVPlayer(url: url)
                            playerVC.player?.play()
                            self.navigationController?.pushViewController(playerVC, animated: true)
                        }
                    }
                }
        }
    }
    
    @objc private func mergeVideosAndAudio(_ button: UIButton) {
        let urls = Array(repeating: testMp4, count: 10)
        mergeVideosAndAudio(urls: urls)
    }
    
    private func mergeVideosAndAudio(urls: [URL]) {
        showLoading()
        
        VideoBuilder()
            .addVideos(withURLs: urls)
            .setAudio(withURL: soundMp3)
            .generateVideoFromVideos { [weak self] url in
                DispatchQueue.main.async {
                    self?.hideLoading()
                    
                    if let url = url, let self = self {
                        let playerVC = AVPlayerViewController()
                        playerVC.player = AVPlayer(url: url)
                        playerVC.player?.play()
                        self.navigationController?.pushViewController(playerVC, animated: true)
                    }
                }
            }
    }
    
    @objc private func mergeVideosAndAudioByImagePicker(_ button: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else { return }
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .savedPhotosAlbum
        imagePickerController.mediaTypes = [kUTTypeMovie as String]
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func showFilteredPlayer() {
        let playerVC = PlayerViewController()
        playerVC.url = testMp4
        navigationController?.pushViewController(playerVC, animated: true)
    }
    
    @objc private func showQueuePlayer() {
        let videoURLs = [testMp4, test2Mp4]
        let playerItems: [AVPlayerItem] = videoURLs.map { AVPlayerItem(url: $0) }
        let queuePlayerItems = playerItems.map { QueuePlayerItem(item: $0, startAt: 3, endAt: 6) }
        
        let playerVC = QueuePlayerController()
        playerVC.queuePlayerItems = queuePlayerItems
        playerVC.player.play()
        
        navigationController?.pushViewController(playerVC, animated: true)
    }
    
    func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard let mediaType = info[.mediaType] as? String,
              mediaType == (kUTTypeMovie as String),
              let url = info[.mediaURL] as? URL else {
            return
        }
        
        let urls = Array(repeating: url, count: 10)
        mergeVideosAndAudio(urls: urls)
    }
    
}
