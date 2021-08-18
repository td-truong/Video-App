//
//  ViewController.swift
//  VideoApp
//
//  Created by Duy Truong on 05/07/2021.
//

import AVKit
import MobileCoreServices

class ViewController: UIViewController {
    
    let mergeImagesAndAudioButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Merge images and audio", for: .normal)
        button.addTarget(self, action: #selector(mergeImagesAndAudio(_:)), for: .touchUpInside)
        return button
    }()
    
    let mergeVideosAndAudioButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Merge videos and audio", for: .normal)
        button.addTarget(self, action: #selector(mergeVideosAndAudio(_:)), for: .touchUpInside)
        return button
    }()
    
    let mergeVideosAndAudio2ByImagePickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Merge videos and audio by image picker", for: .normal)
        button.addTarget(self, action: #selector(mergeVideosAndAudioByImagePicker(_:)), for: .touchUpInside)
        return button
    }()
    
    let showButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Show", for: .normal)
        button.addTarget(self, action: #selector(showPlayer), for: .touchUpInside)
        return button
    }()
    
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
            mergeVideosAndAudio2ByImagePickerButton,
            showButton
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
                .setAudio(withURL: Bundle.main.url(forResource: "Sound", withExtension: "mp3")!)
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
        let urls = Array(repeating: Bundle.main.url(forResource: "test", withExtension: "mp4")!, count: 10)
        mergeVideosAndAudio(urls: urls)
    }
    
    private func mergeVideosAndAudio(urls: [URL]) {
        showLoading()
        
        VideoBuilder()
            .addVideos(withURLs: urls)
            .setAudio(withURL: Bundle.main.url(forResource: "Sound", withExtension: "mp3")!)
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
    
    @objc private func showPlayer() {
        let playerVC = PlayerViewController()
        playerVC.url = Bundle.main.url(forResource: "test", withExtension: "mp4")!
        navigationController?.pushViewController(playerVC, animated: true)
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
