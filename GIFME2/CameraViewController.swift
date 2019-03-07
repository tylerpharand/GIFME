//
//  CameraViewController.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-02-28.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer


class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, PageObservation, CameraDelegate {
    
    var parentPageViewController: PageViewController!
    weak var delegate: StickerDelegate?
    
    @IBOutlet var flashButton: UIButton!
    @IBOutlet var flashOverlay: UIView!
    @IBOutlet var shutterBlur: UIVisualEffectView!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!

    var frontCamera: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
    var backCamera: AVCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
    var currentCamera: AVCaptureDevice?
    
    var usingFrontCamera = false
    var captureDevice : AVCaptureDevice?
    
    var imageArray: [Data] = []
    var generatingGif = false
    var flashOn = false
    
    let CAPTURE_WIDTH = 250
    let JPG_COMPRESSION = 0.4
    let SHUTTER_INTERVAL = 0.1
    let MAX_IMG_COUNT = 50
    let CIRCLE_DURATION = 5.0
    
    //keeps track of initial volume
    var audioSession: AVAudioSession?
    var volume: Float = 0
    var volumeTime: Int = 0
    var volumeButtonTimer: Timer?
    
    // shutter flash
    var timer: Timer?
    
    @IBAction func reverseCamera(_ sender: Any) {
        toggleCamera()
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        flashOn = !flashOn
        flashButton.layer.opacity = flashOn ? 1 : 0.3
    }
    
    func getFrontCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    }
    
    func getBackCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shutterBlur.clipsToBounds = true
        shutterBlur.layer.cornerRadius = 35
        generatingGif = false
        
        // double tap to flip camera
        let doubleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleCamera))
        doubleTap.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTap)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // prevent volume from changing...
        (MPVolumeView().subviews.filter{NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}.first as? UISlider)?.setValue(volume, animated: false)
        
        if currentTime() - volumeTime > 500 {
            print("Start recording")
            self.startRecording()
            volumeButtonRecord()
        }
        
        volumeTime = currentTime()
    }
    
    func volumeButtonRecord() {
        print("Setting timer...")
        if self.volumeButtonTimer == nil {
            self.volumeButtonTimer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(checkIfStillVolumeRecording),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    @objc func checkIfStillVolumeRecording() {
        
        print(currentTime() - volumeTime)
        if currentTime() - volumeTime > 500 {
            
            if self.volumeButtonTimer != nil {
                self.volumeButtonTimer?.invalidate()
                self.volumeButtonTimer = nil
            }
            
            self.stopRecording()
            print("Stop recording")
        }
    }
    
    func currentTime() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("Adding observer...")
        // volume button for recording:
        audioSession = AVAudioSession.sharedInstance()
        volume = (audioSession?.outputVolume)!-0.1 //if the user is at 1 (full volume)
        try! audioSession?.setActive(true)
        audioSession?.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
        let volumeIndicator = MPVolumeView()
        volumeIndicator.tag = 100
        self.view.insertSubview(volumeIndicator, at: 0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        audioSession?.removeObserver(self, forKeyPath: "outputVolume")
        self.view.viewWithTag(100)?.removeFromSuperview()
    }
    
    func generatingGif(state: Bool){
        self.generatingGif = state
    }
    
    @objc func toggleCamera() {
        // flip camera direction
        usingFrontCamera = !usingFrontCamera
        do{
            captureSession.removeInput(captureSession.inputs.first!)
            
            if(usingFrontCamera){
                captureDevice = getFrontCamera()
            }else{
                captureDevice = getBackCamera()
            }
            let newInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(newInput)
        } catch { print(error.localizedDescription) }
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        do {
            let input = try AVCaptureDeviceInput(device: self.backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    func setupLivePreview() {
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        
        self.view.layer.insertSublayer(videoPreviewLayer, at: 0)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.view.frame
            }
        }
    }
    
    @objc func takePhoto() {
        
        if imageArray.count < MAX_IMG_COUNT && !generatingGif {
            DispatchQueue.main.async {
                let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                self.stillImageOutput.capturePhoto(with: settings, delegate: self)
                print("Appending image data...")
            }
        } else if !generatingGif{
            stopRecording()
            generateGif()
            print("Generating GIF!")
        }
        
    }
    
    func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutableRawPointer) {
        if keyPath == "outputVolume"{
            print("Capture photo here...")
        }
    }
    
    @IBAction func shutterTapped(_ sender: Any) {
        // touch up inside
        stopRecording()
    }
    
    @IBAction func shutterTouchUp(_ sender: Any) {
        // touch up outside
        stopRecording()
    }
    
    @IBAction func shutterDown(_ sender: Any) {
        // touch down
        startRecording()
    }
    
    
    func startRecording() {
        if usingFrontCamera && flashOn {
            flashOverlay.layer.opacity = 0.8
        } else {
            toggleTorch(on: flashOn)
        }
        
        imageArray.removeAll()
        
        if self.timer == nil {
            timer = Timer.scheduledTimer(
                timeInterval: SHUTTER_INTERVAL,
                target: self,
                selector: #selector(takePhoto),
                userInfo: nil,
                repeats: true
            )
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.shutterBlur.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        })
        
        // add recording ring
        let ring = CircleView(frame: self.shutterBlur.contentView.frame)
        ring.tag = 200
        self.shutterBlur.contentView.addSubview(ring)
        ring.animateCircle(duration: CIRCLE_DURATION)
    }
    
    func stopRecording() {
        print("Stopping recording...")
        if usingFrontCamera && flashOn {
            flashOverlay.layer.opacity = 0
        } else {
            toggleTorch(on: false)
        }
        
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.shutterBlur.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
        
        // remove recording ring
        self.shutterBlur.contentView.viewWithTag(200)?.removeFromSuperview()
        
        if !generatingGif {
            generateGif()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard var image = UIImage(data: photo.fileDataRepresentation()!)?.resized(toWidth: CGFloat(CAPTURE_WIDTH))
            else { return }
        
        if usingFrontCamera {
            let ciImage: CIImage = CIImage(cgImage: image.cgImage!).oriented(forExifOrientation: 1)
            let flippedImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            image = UIImage.convert(from: flippedImage)
        }
        
        let imageData = UIImageJPEGRepresentation(image, CGFloat(JPG_COMPRESSION))  // drop resolution
        imageArray.append(imageData!)
    }
    
    func generateGif() {
        generatingGif = true
        
        // show processing modal
        let popup = storyboard?.instantiateViewController(withIdentifier: "processingModal") as! ProcessingModal
        
        
        // reduce size of imageArray to approximately 15
        let reduction: Int = {
            switch self.imageArray.count {
                case 0...19:
                    return 1
                case 20...34:
                    return 2
                case 35...:
                    return 3
                default:
                    return 1
            }
        }()
        
        self.imageArray = self.imageArray.enumerated().flatMap { index, element in index % reduction == 0 ? element : nil }
        
        print(imageArray.count)
        
        popup.imageArray = self.imageArray  // pass image data for processing
        popup.delegate = self.delegate  // pass along StickerDelegate ref for HomeViewController
        popup.cameraViewDelegate = self
        let navigationController = UINavigationController(rootViewController: popup)
        navigationController.setNavigationBarHidden(true, animated: true)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(navigationController, animated: false, completion: nil)
        
        imageArray.removeAll()
    }
    
    func getParentPageViewController(parentRef: PageViewController) {
        // makes CameraViewController aware of its parent, PageViewController
        // CameraViewController is a delegate for changing the page to HomeViewController
        parentPageViewController = parentRef
    }
    
    @IBAction func grabberTapped(_ sender: Any) {
        parentPageViewController.goToPreviousPage(sender: self, animated: true)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
}

enum CameraControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    static func convert(from ciImage: CIImage) -> UIImage{
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}


protocol CameraDelegate: class {
    func generatingGif(state: Bool)
}

