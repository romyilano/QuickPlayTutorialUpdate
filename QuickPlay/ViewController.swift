//
//  ViewController.swift
//  QuickPlay
//
//  Created by Michael Briscoe on 1/5/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Photos

class ViewController: UIViewController {
    @IBOutlet weak var videoTable: UITableView!
    
    var imagePicker: UIImagePickerController!
    var videoURLs = [NSURL]()
    var currentTableIndex = -1
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - IBActions
    @IBAction func addVideoClip(sender: AnyObject) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        imagePicker.allowsEditing = false
        imagePicker.mediaTypes = ["public.movie"]
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func addRemoteStream(sender: AnyObject) {
        let theAlert = UIAlertController(title: "Add Remote Stream",
                                         message: "Enter URL for remote stream.",
                                         preferredStyle: UIAlertControllerStyle.alert)
        
        theAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
        theAlert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: {
            action in
            
            
            let theTextField = theAlert.textFields![0] as UITextField
            self.addVideoURL(url: NSURL(string: theTextField.text!)!)
        }))
        
        theAlert.addTextField(configurationHandler: {
            textField in
            textField.text = "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
        })
        
        present(theAlert, animated: true, completion:nil)
        
    }
    
    func addVideoURL(url: NSURL) {
        videoURLs.append(url)
        videoTable.reloadData()
    }
    
    @IBAction func deleteVideoClip(sender: AnyObject) {
        if currentTableIndex != -1 {
            let theAlert = UIAlertController(title: "Remove Clip",
                                             message: "Are you sure you want to remove this video clip from playlist?",
                                             preferredStyle: UIAlertControllerStyle.alert)
            
            theAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil))
            theAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {
                action in
                self.videoURLs.remove(at: self.currentTableIndex)
                self.videoTable.reloadData()
                self.currentTableIndex = -1
            }))
            
            present(theAlert, animated: true, completion:nil)
            
        }
    }
    
    @IBAction func playVideoClip(sender: AnyObject) {
        print("\(#function)")
        guard currentTableIndex != -1 else { return }
        
        let player = AVPlayer(url: videoURLs[currentTableIndex] as URL)
        player.allowsExternalPlayback = false
        
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }
    
    @IBAction func playAllVideoClips(sender: AnyObject) {
        guard videoURLs.count > 0 else { return }
        var queue = [AVPlayerItem]()
        for url in videoURLs {
            let videoClip = AVPlayerItem(url: url as URL)
            queue.append(videoClip)
        }
        
        let queuePlayer = AVQueuePlayer(items: queue)
        queuePlayer.allowsExternalPlayback = false
        let playerViewController = AVPlayerViewController()
        
        present(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
        
        queue = []
    }
    
    // MARK: - Helpers
    func previewImageFromVideo(url: NSURL) -> UIImage? {
        let asset = AVAsset(url: url as URL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            return nil
        }
    }
    
    
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc internal func imagePickerController(_ picker: UIImagePickerController,
                                              didFinishPickingMediaWithInfo info: [String : Any]) {
        checkPhotoPermission { [ weak self] in
            guard let strongSelf = self,
                let imagePath = info["UIImagePickerControllerReferenceURL"] as? NSURL else { return }
            
            strongSelf.addVideoURL(url: imagePath)
            
            strongSelf.imagePicker.dismiss(animated: true, completion: nil)
            strongSelf.imagePicker = nil
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        imagePicker.dismiss(animated: true, completion: nil)
        imagePicker = nil
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoURLs.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoClipCell") as! VideoTableViewCell
        
        cell.clipName.text = "Video Clip \(indexPath.row + 1)"
        
        if let previewImage = previewImageFromVideo(url: videoURLs[indexPath.row]) {
            cell.clipThumbnail.image = previewImage
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentTableIndex = indexPath.row
    }
}

extension ViewController {
    // https://stackoverflow.com/a/47343280/1492368
    func checkPhotoPermission(handler: @escaping () -> Void) {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            // Access is already granted by user
            handler()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    // Access is granted by user
                    handler()
                }
            }
        default:
            print("Error: no access to photo album.")
        }
    }
}
