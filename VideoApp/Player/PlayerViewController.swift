//
//  PlayerViewController.swift
//  VideoApp
//
//  Created by Machintosh on 14/07/2021.
//

import AVKit
import MetalPetal

class PlayerViewController: UIViewController {
    
    var url: URL!
    
    private var asset: AVAsset!
    private var playerItem: AVPlayerItem!
    
    private let avPlayerVC = AVPlayerViewController()
    private var filterCollectionView: UICollectionView!
    
    private var player: AVPlayer! {
        return avPlayerVC.player!
    }

    private lazy var context = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    private lazy var filter = MTICoreImageUnaryFilter()
    
    private var showFilter = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupAVPlayerVC()
        setupFilterCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(Thread.isMainThread)
        DispatchQueue.main.async {
            print(Thread.isMainThread)
            self.playVideo()
            self.setupFilter()
        }
    }
    
    private func setupNavigationBar() {
        title = "Video"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Export", style: .done, target: self, action: #selector(export)),
            UIBarButtonItem(title: "Filter", style: .done, target: self, action: #selector(toggleFilter))
        ]
    }
    
    private func setupAVPlayerVC() {
        addChild(avPlayerVC)
        avPlayerVC.view.frame = view.frame
        view.addSubview(avPlayerVC.view)        
        avPlayerVC.didMove(toParent: self)
    }
    
    private func setupFilterCollectionView() {
        let filterLayout = UICollectionViewFlowLayout()
        filterLayout.scrollDirection = .horizontal
        filterLayout.itemSize = CGSize(width: 64, height: 64)
        filterLayout.minimumInteritemSpacing = 16
        
        filterCollectionView = UICollectionView(frame: .zero, collectionViewLayout: filterLayout)
        filterCollectionView.isHidden = true
        filterCollectionView.showsHorizontalScrollIndicator = false
        filterCollectionView.translatesAutoresizingMaskIntoConstraints = false
        filterCollectionView.dataSource = self
        filterCollectionView.delegate = self
        filterCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        view.addSubview(filterCollectionView)
        NSLayoutConstraint.activate([
            filterCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            filterCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            filterCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            filterCollectionView.heightAnchor.constraint(equalToConstant: 64)
        ])
    }
    
    private func playVideo() {
        self.asset = AVURLAsset(url: url)
        self.playerItem = AVPlayerItem(asset: asset)
        avPlayerVC.player = AVPlayer(playerItem: playerItem)
        player.play()
    }
    
    private func setupFilter() {
        let videoComposition = MTIVideoComposition(asset: asset, context: context, queue: .main) { [weak self] request in
            guard let self = self, let sourceImage = request.anySourceImage else {
                return MTIImage.black
            }
            
            return FilterGraph.makeImage { output in
                sourceImage => self.filter => output
            }!
        }
        playerItem.videoComposition = videoComposition.makeAVVideoComposition()
    }
    
    @objc private func toggleFilter() {
        showFilter = !showFilter
        filterCollectionView.isHidden = !showFilter
        avPlayerVC.showsPlaybackControls = !showFilter
    }
    
    @objc private func export() {
        
    }
    
    private func selectFilter(_ filterIndex: Int?) {
        guard let filterIndex = filterIndex else {
            filter.filter = nil
            return
        }
        
        filter.filter = CIFilter(name: CIFilterNames[filterIndex])
    }
    
}

extension PlayerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return CIFilterNames.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let image = UIImage(named: "image2")!
        let imageView = UIImageView(image: indexPath.row == 0
                                        ? image
                                        : image.addFilter(CIFilterNames[indexPath.row - 1]))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        
        cell.backgroundView = imageView
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            selectFilter(nil)
        } else {
            selectFilter(indexPath.row - 1)
        }
    }
    
}
