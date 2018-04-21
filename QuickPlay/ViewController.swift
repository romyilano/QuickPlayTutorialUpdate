//
//  ViewController.swift
//  QuickPlay
//
//  Created by Michael Briscoe on 1/5/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {
  @IBOutlet weak var videoTable: UITableView!
  
  var imagePicker: UIImagePickerController!
  var videoURLs = [NSURL]()
  var currentTableIndex = -1

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBAction func addVideoClip(sender: AnyObject) {
    imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
    imagePicker.allowsEditing = false
    imagePicker.mediaTypes = ["public.movie"]
    
    presentViewController(imagePicker, animated: true, completion: nil)
  }
  
  @IBAction func addRemoteStream(sender: AnyObject) {
    let theAlert = UIAlertController(title: "Add Remote Stream",
      message: "Enter URL for remote stream.",
      preferredStyle: UIAlertControllerStyle.Alert)
    
    theAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
    theAlert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.Default, handler: {
      action in
      
      let theTextField = theAlert.textFields![0] as UITextField
      self.addVideoURL(NSURL(string: theTextField.text!)!)
    }))
    
    theAlert.addTextFieldWithConfigurationHandler({
      textField in
      textField.text = "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
    })
    
    presentViewController(theAlert, animated: true, completion:nil)

  }
  
  func addVideoURL(url: NSURL) {
    videoURLs.append(url)
    videoTable.reloadData()
  }
  
  @IBAction func deleteVideoClip(sender: AnyObject) {
    if currentTableIndex != -1 {
      let theAlert = UIAlertController(title: "Remove Clip",
        message: "Are you sure you want to remove this video clip from playlist?",
        preferredStyle: UIAlertControllerStyle.Alert)
      
      theAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
      theAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: {
        action in
        self.videoURLs.removeAtIndex(self.currentTableIndex)
        self.videoTable.reloadData()
        self.currentTableIndex = -1
      }))
      
      presentViewController(theAlert, animated: true, completion:nil)

    }
  }
  
  @IBAction func playVideoClip(sender: AnyObject) {

  }
  
  @IBAction func playAllVideoClips(sender: AnyObject) {

  }
  
  // MARK: - Helpers
  
  func previewImageFromVideo(url: NSURL) -> UIImage? {
    let asset = AVAsset(URL: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    var time = asset.duration
    time.value = min(time.value, 2)
    
    do {
      let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
      return UIImage(CGImage: imageRef)
    } catch {
      return nil
    }
  }


}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let theImagePath: NSURL = info["UIImagePickerControllerReferenceURL"] as! NSURL
    addVideoURL(theImagePath)
    
    imagePicker.dismissViewControllerAnimated(true, completion: nil)
    imagePicker = nil
  }
  
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    imagePicker.dismissViewControllerAnimated(true, completion: nil)
    imagePicker = nil
  }

  
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return videoURLs.count
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }

}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("VideoClipCell") as! VideoTableViewCell
    
    cell.clipName.text = "Video Clip \(indexPath.row + 1)"
    
    if let previewImage = previewImageFromVideo(videoURLs[indexPath.row]) {
      cell.clipThumbnail.image = previewImage
    }

    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    currentTableIndex = indexPath.row
  }
}

