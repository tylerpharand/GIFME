//
//  PageViewController.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-02-28.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var currentIndex = 0
    let bgView = UIView(frame: UIScreen.main.bounds)
//    let statusBar = UIVisualEffectView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))

    lazy var orderedViewControllers : [UIViewController] = {
        
        let homeViewController : HomeViewController = {
            let vc: HomeViewController = self.newVC(viewController: "HomeViewController") as! HomeViewController
            return vc
        }()
        
        let cameraViewController : CameraViewController = {
            let vc: CameraViewController = self.newVC(viewController: "CameraViewController") as! CameraViewController
            vc.delegate = homeViewController
            return vc
        }()
        
        return [homeViewController, cameraViewController]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
        (orderedViewControllers[1] as! CameraViewController).setupCamera()
        
        bgView.backgroundColor = UIColor.white
        view.insertSubview(bgView, at: 0)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth]
        blurEffectView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20)
        view.addSubview(blurEffectView)
        
    }
    
    func newVC(viewController: String) -> UIViewController {
        
        let childViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
        
        let childWithParent = childViewController as! PageObservation
        childWithParent.getParentPageViewController(parentRef: self)
        
        return childViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        self.currentIndex = viewControllerIndex
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        self.currentIndex = viewControllerIndex
        let nextIndex = viewControllerIndex + 1
        
        guard orderedViewControllers.count != nextIndex else {
            return nil
        }
        
        guard orderedViewControllers.count > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


extension UIPageViewController {
    
    func goToNextPage(sender: AnyObject, animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) else { return }
        setViewControllers([nextViewController], direction: .forward, animated: animated, completion: nil)
    }
    
    func goToPreviousPage(sender: AnyObject, animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let previousViewController = dataSource?.pageViewController(self, viewControllerBefore: currentViewController) else { return }
        setViewControllers([previousViewController], direction: .reverse, animated: animated, completion: nil)
    }
    
}
