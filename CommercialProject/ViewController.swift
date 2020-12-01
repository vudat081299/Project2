//
//  ViewController.swift
//  CommercialProject
//
//  Created by Vũ Quý Đạt  on 18/11/2020.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var switchCameraButton: UIButton!
    @IBOutlet weak var captureImageButton: UIButton!
    
    @IBOutlet weak var capturedImageView: CapturedImageView!
    @IBOutlet weak var leadingConstraintCIV: NSLayoutConstraint!
    
    //MARK:- Vars
    var captureSession : AVCaptureSession!
    
    var backCamera : AVCaptureDevice!
    var frontCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    
    var previewLayer : AVCaptureVideoPreviewLayer!
    var videoOutput : AVCaptureVideoDataOutput!
    
    var takePicture = false
    var backCameraOn = true
    var isFirstCap = true
    
    //MARK:- View Components
//    let switchCameraButton : UIButton = {
//        let button = UIButton()
        let image = UIImage(named: "switchcamera")?.withRenderingMode(.alwaysTemplate)
//        button.setImage(image, for: .normal)
//        button.tintColor = .white
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//
//    let captureImageButton : UIButton = {
//        let button = UIButton()
//        button.backgroundColor = .white
//        button.tintColor = .white
//        button.layer.cornerRadius = 25
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
    
//    let capturedImageView = CapturedImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        switchCameraButton.setImage(image, for: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.translatesAutoresizingMaskIntoConstraints = false
        
//        captureImageButton.backgroundColor = .white
        captureImageButton.tintColor = .white
        captureImageButton.translatesAutoresizingMaskIntoConstraints = false
//        capturedImageView.frame = CGRect(x: 0, y: 0, width: capturedImageViewContainer.frame.size.width, height: capturedImageViewContainer.frame.size.height)
//        capturedImageViewContainer.addSubview(capturedImageView)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
    }
    
    //MARK:- Camera Setup
    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            //start configuration
            self.captureSession.beginConfiguration()
            
            //session specific configuration
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            //setup inputs
            self.setupInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }
            
            //setup output
            self.setupOutput()
            
            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.captureSession.startRunning()
        }
    }
    
    func setupInputs(){
        //get back camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }
        
        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }
        
        //connect back camera input to session
        captureSession.addInput(backInput)
    }
    
    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.frame = self.view.layer.frame
        
//        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    func switchCameraInput(){
        //don't let user spam the button, fun for the user, not fun for performance
        switchCameraButton.isUserInteractionEnabled = false
        
        //reconfigure the input
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        
        //deal with the connection again for portrait mode
        videoOutput.connections.first?.videoOrientation = .portrait
        
        //mirror the video stream for front camera
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        
        //commit config
        captureSession.commitConfiguration()
        
        //acitvate the camera button again
        switchCameraButton.isUserInteractionEnabled = true
    }
    
    //MARK:- Actions
//    @objc func captureImage(_ sender: UIButton?){
//        takePicture = true
//    }
//
//    @objc func switchCamera(_ sender: UIButton?){
//        switchCameraInput()
//    }
    @IBAction func capImage(_ sender: UIButton) {
        if (isFirstCap) {
            isFirstCap = false
            UIView.animate(withDuration: 0.5,
                           delay: 0.4,
                           options: [.curveEaseIn],
                           animations: { [weak self] in
                            self?.leadingConstraintCIV.constant = ((self?.view.frame.size.width)!) - 20 - (self?.capturedImageView.frame.size.width)!
                            self?.view.layoutIfNeeded()
              }, completion: nil)
        }
        
        tapticFeedBack()
        takePicture = true
    }
    
    @IBAction func upload(_ sender: UIBarButtonItem) {
        let user = AnnotationUpload(name: "Test", description: "Test", latitude: String(MapViewController.userLocation.coordinate.latitude), longitude: String(MapViewController.userLocation.coordinate.longitude), file: File(data: (self.capturedImageView.image?.pngData())!, filename: "test"))
        ResourceRequest<AnnotationUpload>(resourcePath: "annotations").save(user) { [weak self] result in
          switch result {
          case .failure:
            ErrorPresenter.showError(message: "There was a problem saving the user", on: self)
          case .success:
            DispatchQueue.main.async { [weak self] in
                print("successful created annotation!")
//              self?.navigationController?.popViewController(animated: true)
            }
          }
        }
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        tapticFeedBack()
        switchCameraInput()
    }
}

func tapticFeedBack() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !takePicture {
            return //we have nothing to do with the image buffer
        }
        
        //try and get a CVImageBuffer out of the sample buffer
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        //get a CIImage out of the CVImageBuffer
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        
        //get UIImage out of CIImage
        let uiImage = UIImage(ciImage: ciImage)
        
        DispatchQueue.main.async {
            self.capturedImageView.image = uiImage.resized(toWidth: 150.0)
            self.takePicture = false
        }
    }
}

extension ViewController {
    //MARK:- View Setup
    func setupView(){
       view.backgroundColor = .black
//       view.addSubview(switchCameraButton)
//       view.addSubview(captureImageButton)
//       view.addSubview(capturedImageView)
       
//       NSLayoutConstraint.activate([
//           switchCameraButton.widthAnchor.constraint(equalToConstant: 30),
//           switchCameraButton.heightAnchor.constraint(equalToConstant: 30),
//           switchCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
//           switchCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
//
//           captureImageButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
//           captureImageButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
//           captureImageButton.widthAnchor.constraint(equalToConstant: 50),
//           captureImageButton.heightAnchor.constraint(equalToConstant: 50),
//
//           capturedImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
//           capturedImageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
//           capturedImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),
//           capturedImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5, constant: -70)
//       ])
       
//       switchCameraButton.addTarget(self, action: #selector(switchCamera(_:)), for: .touchUpInside)
//       captureImageButton.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
    }
    
    //MARK:- Permissions
    func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
          case .authorized:
            return
          case .denied:
            abort()
          case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
            { (authorized) in
              if(!authorized){
                abort()
              }
            })
          case .restricted:
            abort()
          @unknown default:
            fatalError()
        }
    }
}






