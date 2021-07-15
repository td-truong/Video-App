//
//  ViewController.swift
//  VideoApp
//
//  Created by Duy Truong on 05/07/2021.
//

import AVKit

class ViewController: UIViewController {
    
    let processButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Process", for: .normal)
        button.addTarget(self, action: #selector(process), for: .touchUpInside)
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
        
        let stackView = UIStackView(arrangedSubviews: [processButton, showButton])
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
    
    @objc private func process() {
        var images: [UIImage] = []
        for i in 0...3 {
            images.append(UIImage(named: "image\(i)")!)
        }
        
        VideoGenerator(images: images, audioURL: Bundle.main.url(forResource: "Sound", withExtension: "mp3")!)
            .process()
    }
    
    @objc private func showPlayer() {
        let playerVC = PlayerViewController()
        playerVC.url = Bundle.main.url(forResource: "test", withExtension: "mp4")!
        navigationController?.pushViewController(playerVC, animated: true)
    }
    
}

