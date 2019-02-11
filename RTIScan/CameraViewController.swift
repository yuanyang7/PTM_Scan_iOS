//
//  CameraViewController.swift
//  RTIScan
//
//  Created by yang yuan on 1/27/19.
//  Copyright © 2019 Yuan Yang. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    let captureSession = AVCaptureSession()
    //var previewLayer:CALayer!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice:AVCaptureDevice!
    
    var take_photo = false
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareCamera()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func backToMenu() {
        print("Back!")
        //self.performSegue(withIdentifier: "HomeSegue", sender: self)
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func takePhoto() {
        print("Take photo")
        take_photo = true
    }
    
    func prepareCamera () {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        if let captureDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first {
            
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                
                captureSession.addInput(captureDeviceInput)
            }catch {
                print(error.localizedDescription)
            }
            
            //todo if let
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            //self.previewLayer.frame = self.view.bounds
            
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput()
            //dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput) {
                captureSession.addOutput(dataOutput)
            }
            
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.yuanyang.RTIScan")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
        }
 
    }


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if take_photo {
            take_photo = false
            //get image from sample buffer
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                let photoVC = UIStoryboard(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "PhotoVC") as! PhotoViewController
                photoVC.takenPhoto = image
                
                DispatchQueue.main.async {
                    self.present(photoVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right) //todo
            }
        }
        return nil
    }
    
    /*
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        guard
            let conn = self.previewLayer?.connection,
            conn.isVideoOrientationSupported
            else { return }
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait: conn.videoOrientation = .portrait
        case .landscapeRight: conn.videoOrientation = .landscapeLeft
        case .landscapeLeft: conn.videoOrientation = .landscapeRight
        case .portraitUpsideDown: conn.videoOrientation = .portraitUpsideDown
        default: conn.videoOrientation = .portrait
        }
    }
    */
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
