//
//  ProcessingModal.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-03-04.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit

class ProcessingModal: UIViewController {

    @IBOutlet var gifTileA: UIImageView!
    @IBOutlet var gifTileB: UIImageView!
    @IBOutlet var gifTileC: UIImageView!
    
    @IBOutlet var gifTileA_topConstraint: NSLayoutConstraint!
    @IBOutlet var gifTileB_topConstraint: NSLayoutConstraint!
    @IBOutlet var gifTileC_topConstraint: NSLayoutConstraint!
    
    @IBOutlet var popup: ColorButton!
    @IBOutlet var bgOverlay: UIView!
    
    var imageArray: [Data] = []
    
    weak var cameraViewDelegate: CameraDelegate?
    weak var delegate: StickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let b64Images: [String] = {
            var output: [String] = []
            for image in self.imageArray{
                output.append(image.base64EncodedString())
            }
            return output
        }()
        
        fetchGif(b64data: b64Images)
    }
    
    func fetchGif(b64data: [String]) {
        let parameters = ["style": "default", "img_data": b64data] as [String : Any]
        let url = URL(string: "https://gif3.herokuapp.com/api/gifify")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error { print(error.localizedDescription)}
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return }
            guard let data = data else { return }
            
            DispatchQueue.main.async {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:String]
                    
                    let newSticker = Sticker(
                        stickerUrl: json["gif_url"]!,
                        stickerData: try Data(contentsOf: URL(string: json["gif_url"]!)!)
                    )
                    
                    self.delegate?.addSticker(sticker: newSticker)
                    
                    let popup : StickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "StickerViewController") as! StickerViewController
                    popup.stickerData = newSticker
                    popup.stickerIndex = 0
                    popup.delegate = self.delegate
                    
                    let navigationController = UINavigationController(rootViewController: popup)
                    navigationController.setNavigationBarHidden(true, animated: true)
                    navigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    
                    self.imageArray.removeAll()
                    self.cameraViewDelegate?.generatingGif(state: false)
                    let transition: CATransition = CATransition()
                    transition.duration = 0.3
                    transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                    transition.type = kCATransitionFade
                    transition.subtype = kCATransitionFromBottom
                    self.view.window!.layer.add(transition, forKey: nil)
                    
                    weak var pvc = self.presentingViewController!
                    
                    self.dismiss(animated: false, completion: {
                        pvc?.present(navigationController, animated: true, completion: nil)
                    })
                    
                } catch let error as NSError {
                    print(error)
                    self.dismissModal()
                }
            }
        })
        task.resume()
    }
    
    @objc func dismissModal() {
        self.imageArray.removeAll()
        self.cameraViewDelegate?.generatingGif(state: false)
        let transition: CATransition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        transition.subtype = kCATransitionFromBottom
        self.view.window!.layer.add(transition, forKey: nil)
        self.dismiss(animated: false, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.popup.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        bgOverlay.layer.opacity = 0
        bgOverlay.isOpaque = false
        
        self.gifTileA_topConstraint.constant = -5
        self.gifTileB_topConstraint.constant = 2.5
        self.gifTileC_topConstraint.constant = 10
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async {
            // popup grow animation
            UIView.animate(withDuration: 0.3, animations: {
                self.popup.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.popup.layer.opacity = 1
                self.bgOverlay.layer.opacity = 0.5
            })
            
            // tile hover animation
            UIView.animate(withDuration: 1, delay: 0, options: [.repeat, .autoreverse] , animations: {
                self.gifTileA_topConstraint.constant = 0
                self.gifTileB_topConstraint.constant = 2.5
                self.gifTileC_topConstraint.constant = 5
                self.view.layoutIfNeeded()
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
