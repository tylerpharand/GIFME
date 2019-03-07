//
//  StickerViewController.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-03-01.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//
//  DismissVC Src: https://stackoverflow.com/questions/29290313/in-ios-how-to-drag-down-to-dismiss-a-modal

import UIKit
import SwiftyGif
import SCSDKCreativeKit
import Photos

class StickerViewController: UIViewController {
    
    var panGestureRecognizer: UIPanGestureRecognizer?
    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    
    weak var delegate: StickerDelegate?
    var stickerData : Sticker?
    var stickerIndex : Int?
    
    @IBOutlet var stickerPreview: UIImageView!
    @IBOutlet var deleteButton: ColorButton!
    @IBOutlet var snapButton: ColorButton!
    @IBOutlet var saveButton: ColorButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer!)
        
        let tap_deletebutton = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        deleteButton.addGestureRecognizer(tap_deletebutton)
        
        let tap_snapbutton = UITapGestureRecognizer(target: self, action: #selector(sendSnap))
        snapButton.addGestureRecognizer(tap_snapbutton)
        
        let tap_savebutton = UITapGestureRecognizer(target: self, action: #selector(saveSticker))
        saveButton.addGestureRecognizer(tap_savebutton)

        stickerPreview.image = UIImage.gifImageWithData((stickerData?.stickerData)!)
        
        self.view.clipsToBounds = false
        self.view.layer.borderWidth = 1
        self.view.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        
        let shadowLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(rect: self.view.layer.bounds).cgPath
            layer.fillColor = UIColor.white.cgColor
            layer.shadowColor = UIColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.25).cgColor
            layer.shadowPath = layer.path
            layer.shadowOffset = CGSize(width: 0, height: 2.0)
            layer.shadowOpacity = 1
            layer.shadowRadius = 20
            return layer
        }()
        
        self.view.layer.insertSublayer(shadowLayer, at: 0)
        
    }
    
    @objc func sendSnap(_ sender: UITapGestureRecognizer) {
        print("Sending sticker to Snapchat")
        
//        let sticker = SCSDKSnapSticker(stickerImage: (stickerData?.stickerPreview)!)
        
        let sticker = SCSDKSnapSticker(
            stickerUrl: URL(string: (stickerData?.stickerUrl)!)!,
            isAnimated: true
        )
        
        let snap = SCSDKNoSnapContent()
        snap.sticker = sticker
        
        let api = SCSDKSnapAPI(content: snap)
        api.startSnapping(completionHandler: { (error: Error?) in
            /* Do something */
        })
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.delegate?.removeSticker(index: self.stickerIndex!)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func saveSticker(_ sender: UITapGestureRecognizer) {
        print("Saving sticker!")
        DispatchQueue.main.async {
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: (self.stickerData?.stickerData)!, options: nil)
            }) { (success, error) in
                if let error = error {
                    print(error)
                } else {
                    let alert = UIAlertController(title: "Success", message: "Sticker saved to camera roll", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        
        if panGesture.state == .began {
            originalPosition = view.center
            currentPositionTouched = panGesture.location(in: view)
        } else if panGesture.state == .changed {
            view.frame.origin = CGPoint(
                x: 0,
                y: ((translation.y > 0) ? translation.y : 0)
            )
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)
            
            if (velocity.y >= 1500 || translation.y > self.view.bounds.height*0.3) {
                UIView.animate(withDuration: 0.15
                    , animations: {
                        self.view.frame.origin = CGPoint(
                            x: self.view.frame.origin.x,
                            y: self.view.frame.size.height
                        )
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition!
                })
            }
        }
    }
}
