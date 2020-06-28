//
//  ViewController.swift
//  WatchItLater
//
//  Created by Weiran Zhang on 25/12/2016.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit
import PromiseKit

class ViewController: UIViewController {
    var instapaperAPI: InstapaperAPI?
    var folder: InstapaperFolder = .unread

    private var videos: [Video]?
    private var dataSource: UICollectionViewDiffableDataSource<Section, Video>?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        observeNotifications()

        dataSource = makeDataSource()
        collectionView.dataSource = dataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        performFetch()
    }

    @objc func performFetch() {
        instapaperAPI?.storedAuth().then {
            return self.fetchFolders()
        }.done { [weak self] folders in
            return self?.fetchVideos(folders)
        }.done { [weak self] in
            self?.setNeedsFocusUpdate()
            self?.updateFocusIfNeeded()
        }.catch { [weak self] _ in
            self?.performSegue(withIdentifier: "ShowLoginSegue", sender: self)
        }
    }
    
    @discardableResult
    func fetchVideos(_ folders: [Int]) -> Promise<Void> {
        return instapaperAPI!.fetch(folders).done { [weak self] bookmarks in
            let videos = bookmarks.filter {
                ($0.urlString.contains("vimeo.com") || $0.urlString.contains("youtube.com") || $0.urlString.contains("youtu.be"))
            }

            let syncedVideos = videos.map { video -> (Video) in
                if let existingVideo = Database.shared.getVideo(id: video.id) {
                    return existingVideo
                } else {
                    Database.shared.addVideo(video)
                    return video
                }
            }

            self?.videos = syncedVideos
            self?.update(with: syncedVideos)
            self?.activityIndicator.stopAnimating()
        }
    }

    func fetchFolders() -> Promise<[Int]> {
        if folder != .other {
            return Promise<[Int]> { seal in
                seal.fulfill([folder.rawValue])
            }
        }

        return instapaperAPI!.fetchFolders()
    }
    
    func observeNotifications() {
        if folder != .archive {
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(self, selector: #selector(performFetch), name: Notification.Name("AuthenticationChanged"), object: nil)
        } else if folder == .unread {
            NotificationCenter.default.addObserver(self, selector: #selector(performFetch), name: Notification.Name.didBecomeActive, object: nil)
        }
    }
    
    override weak var preferredFocusedView: UIView? {
        return collectionView
    }
}

private extension ViewController {
    enum Section: CaseIterable {
        case main
    }

    func makeDataSource() -> UICollectionViewDiffableDataSource<Section, Video> {
        let reuseIdentifier = "VideoCell"

        return UICollectionViewDiffableDataSource(collectionView: collectionView) { (collectionView, indexPath, video) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reuseIdentifier,
                for: indexPath
            ) as! VideoCell

            cell.setImage(image: UIImage(named: "ThumbnailPlaceholder")!)
            cell.posterView.title = video.title

            if let provider = try? VideoProvider.videoProvider(for: video.urlString) {
                provider.videoStream().done {
                    if let thumbnailURL = $0.thumbnailURL {
                        cell.setImageURL(url: thumbnailURL)
                    }
                }.cauterize()
            }

            return cell
        }
    }

    func update(with videos: [Video], animate: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Video>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(videos)
        self.dataSource?.apply(snapshot, animatingDifferences: animate)
    }

    func remove(_ video: Video, animate: Bool = true) {
        if let dataSource = dataSource {
            var snapshot = dataSource.snapshot()
            snapshot.deleteItems([video])
            dataSource.apply(snapshot, animatingDifferences: animate)
        }
    }
}

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue" {
            let cell = sender as! VideoCell
            let indexPath = collectionView.indexPath(for: cell)!
            let video = videos?[indexPath.row]
            
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.video = video
            detailViewController.canArchive = self.folder == .unread
        }
    }
}
