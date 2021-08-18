//
//  LoadingView.swift
//  VideoApp
//
//  Created by Duy Truong on 18/08/2021.
//

import UIKit

class LoadingView: UIView {
    
    lazy var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.style = .whiteLarge
        loadingIndicator.hidesWhenStopped = true
        return loadingIndicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = UIColor(white: 0, alpha: 0.7)

        addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingIndicator.widthAnchor.constraint(equalToConstant: 50),
            loadingIndicator.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func startAnimating() {
        loadingIndicator.startAnimating()
    }
    
    func stopAnimating() {
        loadingIndicator.stopAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UIViewController {
    
    func showLoading() {
        guard let keywindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        let loadingView = LoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        keywindow.addSubview(loadingView)
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: keywindow.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: keywindow.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: keywindow.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: keywindow.bottomAnchor),
        ])
        
        loadingView.startAnimating()
    }

    func hideLoading() {
        guard let keywindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        if let loadingView = keywindow.subviews.first(where: { $0 is LoadingView }) as? LoadingView {
            loadingView.stopAnimating()
            loadingView.removeFromSuperview()
        }
    }
    
}
