//
//  ViewController.swift
//  VideoApp
//
//  Created by Duy Truong on 05/07/2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    let processButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Process", for: .normal)
        button.addTarget(self, action: #selector(process), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    private func setupViews() {
        view.backgroundColor = .white

        view.addSubview(processButton)
        
        NSLayoutConstraint.activate([
            processButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            processButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
    
}

