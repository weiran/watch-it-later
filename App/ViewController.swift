//
//  ViewController.swift
//  Instapaper TV
//
//  Created by Weiran Zhang on 25/12/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    fileprivate let instapaperAPI = InstapaperAPI()
    fileprivate var videos: [Video]?
    
    var isChildViewController: Bool = false
    var hideVideo: Video?
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        instapaperAPI.storedAuth().then {
            self.fetchVideos()
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
    
    func fetchVideos() {
        instapaperAPI.fetch().then { videos -> Void in
            self.videos = videos.filter({ video -> Bool in
                (video.url.contains("vimeo.com") || video.url.contains("youtube.com") || video.url.contains("youtu.be")) && video != self.hideVideo
            })
            self.collectionView.reloadData()
        }.catch { error -> Void in
            // todo: show error
        }
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "VideoArchived"), object: nil, queue: nil) { [weak self] notification in
            if let video = notification.userInfo?["video"] as? Video,
                let index = self?.videos?.index(where: { $0 == video }) {
                self?.videos?.remove(at: index)
                self?.collectionView.performBatchUpdates({
                    self?.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                }, completion: nil)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "AuthenticationChanged"), object: nil, queue: nil) { [weak self] notification in
            self?.fetchVideos()
        }
    }
    
    @IBAction func didReload(_ sender: Any) {
        fetchVideos()
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
            
            if isChildViewController {
                // stop the chain of view controllers being created
            }
        } else if segue.identifier == "ShowLoginSegue" {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.instapaperAPI = instapaperAPI // todo change to dependency injection
        }
    }
}
