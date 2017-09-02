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
    
    fileprivate let instapaperAPI = InstapaperAPI()
    fileprivate var videos: [Video]?
    
    var isChildViewController: Bool = false
    var hideVideo: Video?
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        instapaperAPI.storedAuth().then {
            return self.fetchVideos()
        }.then { _ -> Void in
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }.catch { _ -> Void in
            self.performSegue(withIdentifier: "ShowLoginSegue", sender: self)
        }
        
        observeNotifications()
        
        if isChildViewController {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.scrollDirection = .horizontal
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func fetchVideos() -> Promise<Void> {
        return instapaperAPI.fetch().then { [unowned self] videos -> Void in
            let filteredVideos = videos.filter({ video -> Bool in
                (video.urlString.contains("vimeo.com") || video.urlString.contains("youtube.com") || video.urlString.contains("youtu.be")) && video != self.hideVideo
            })
            
            let syncedVideos = filteredVideos.map { video -> (Video) in
                if let existingVideo = Database.shared.getVideo(id: video.id) {
                    return existingVideo
                } else {
                    Database.shared.addVideo(video)
                    return video
                }
            }
            
            self.videos = syncedVideos
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "VideoArchived"), object: nil, queue: nil) { [weak self] notification in
            if let video = notification.userInfo?["video"] as? Video,
                let strongSelf = self,
                let index = strongSelf.videos?.index(where: { $0 == video }) {
                strongSelf.videos?.remove(at: index)
                strongSelf.collectionView.performBatchUpdates({
                    strongSelf.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                }, completion: { completed in
                    Database.shared.deleteVideo(video)
                })
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AuthenticationChanged"), object: nil, queue: nil) { [weak self] notification in
            _ = self?.fetchVideos()
        }
    }
    
    @IBAction func didReload(_ sender: Any) {
        _ = fetchVideos()
    }
    
    override weak var preferredFocusedView: UIView? {
        return collectionView
    }
    
}


// Collection View
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as! VideoCell
        let video = videos![indexPath.row]
        cell.titleLabel.text = video.title
        cell.thumbnailImageView.image = UIImage.init(named: "ThumbnailPlaceholder")
        
        if let provider = try? VideoProvider.videoProvider(for: video.urlString) {
            _ = provider.thumbnailURL().then {
                cell.thumbnailImageView.imageURL = $0
            }
        }
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue" {
            let cell = sender as! VideoCell
            let indexPath = collectionView.indexPath(for: cell)!
            let video = videos?[indexPath.row]
            
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.video = video
            detailViewController.instapaperAPI = instapaperAPI // todo change to dependency injection
            
            if isChildViewController {
                // stop the chain of view controllers being created
            }
        } else if segue.identifier == "ShowLoginSegue" {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.instapaperAPI = instapaperAPI // todo change to dependency injection
        }
    }
}
