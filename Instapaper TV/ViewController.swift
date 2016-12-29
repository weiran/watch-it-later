//
//  ViewController.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 25/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit

class ViewController: UIViewController, VideosDelegateProtocol {
    
    fileprivate let instapaperAPI = InstapaperAPI()
    fileprivate var videos: [Video]?
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        instapaperAPI.delegate = self
        instapaperAPI.storedAuth()
        instapaperAPI.fetch()
        
        observeNotifications()
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "VideoArchived"), object: nil, queue: nil) { [weak self] notification in
            if let video = notification.userInfo?["video"] as? Video {
                let index = self?.videos?.index(where: { $0 == video })
                self?.videos?.remove(at: index!)
                self?.collectionView.performBatchUpdates({
                    self?.collectionView.deleteItems(at: [IndexPath(row: index!, section: 0)])
                }, completion: nil)
            }
        }
    }
    
    func videosUpdated(videos: [Video]) {
        self.videos = videos.filter({ (video) -> Bool in
            video.url.contains("vimeo.com") || video.url.contains("youtube.com") || video.url.contains("youtu.be")
        })
        collectionView.reloadData()
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
        
        do {
            let provider = try VideoProvider.videoProvider(for: video.url)
            provider.thumbnailURL().then {
                cell.thumbnailImageView.imageURL = $0
            }.catch { error in
                // todo
            }
        } catch _ {
            // todo
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
        }
    }
}
