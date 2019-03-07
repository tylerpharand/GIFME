//
//  ViewController.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-02-27.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, PageObservation, UICollectionViewDelegate, UICollectionViewDataSource, StickerDelegate {
    
    @IBOutlet var cameraFooter: UIView!
    @IBOutlet var collectionView: UICollectionView!
    fileprivate var longPressGesture: UILongPressGestureRecognizer!
    var parentPageViewController: PageViewController!
    var data : [Sticker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        self.collectionView.register(Header.self, forSupplementaryViewOfKind:
            UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        self.collectionView.register(UINib.init(nibName: "StickerCell", bundle: nil), forCellWithReuseIdentifier: "StickerCell")
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongGesture(gesture:)))
        self.collectionView.addGestureRecognizer(longPressGesture)
        
        if let x = UserDefaults.standard.data(forKey: "stickerData") {
            self.data = (NSKeyedUnarchiver.unarchiveObject(with: x) as? [Sticker])!
        } else {
            self.data = ([] as? [Sticker])!
        }
        
    }
    
    func getParentPageViewController(parentRef: PageViewController) {
        parentPageViewController = parentRef
    }
    
    func removeSticker(index: Int) {
        if index < self.data.count {
            self.data.remove(at: index)
            self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
            self.saveData()
        }
    }
    
    func addSticker(sticker: Sticker) {
        self.data.insert(sticker, at: 0)
        self.collectionView.insertItems(at: [IndexPath(row: 0, section: 0)])
        self.saveData()
    }
    
    func saveData() {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: data)
        UserDefaults.standard.set(encodedData, forKey: "stickerData")
    }
    
    @IBAction func cameraIconTapped(_ sender: Any) {
        parentPageViewController.goToNextPage(sender: self, animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showStickerPopup(stickerData: self.data[indexPath.row], stickerIndex: indexPath.row)
    }
    
    func showStickerPopup(stickerData: Sticker, stickerIndex: Int) {
        let popup : StickerViewController = self.storyboard?.instantiateViewController(withIdentifier: "StickerViewController") as! StickerViewController
        popup.stickerData = stickerData
        popup.stickerIndex = stickerIndex
        popup.delegate = self
        
        let navigationController = UINavigationController(rootViewController: popup)
        navigationController.setNavigationBarHidden(true, animated: true)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        switch(gesture.state) {
        
        case .began:
            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
                break
            }
            self.collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            self.collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            self.collectionView.endInteractiveMovement()
        default:
            self.collectionView.cancelInteractiveMovement()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            statusBar.backgroundColor = UIColor.blue
        }
        
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension HomeViewController {
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        (data[sourceIndexPath.item], data[destinationIndexPath.item]) = (data[destinationIndexPath.item], data[sourceIndexPath.item])
//        self.collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: data)
        UserDefaults.standard.set(encodedData, forKey: "stickerData")
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind:
        String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier:
            "headerId", for: indexPath) as! Header
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat =  30
        let collectionViewSize = collectionView.frame.size.width - padding
        return CGSize(width: collectionViewSize/2, height: collectionViewSize/2)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as! StickerCell
        cell.configure(with: data[indexPath.row])
        return cell
    }
    
}

protocol StickerDelegate: class {
    func removeSticker(index: Int)
    func addSticker(sticker: Sticker)
    func showStickerPopup(stickerData: Sticker, stickerIndex: Int)
}

