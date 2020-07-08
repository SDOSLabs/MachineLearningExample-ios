//
//  ViewController.swift
//  MachineLearningExample
//
//  Created by Antonio Martínez Manzano on 06/07/2020.
//  Copyright © 2020 SDOS. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    typealias CompletionBlock = () -> Void
    typealias FailedBlock = (CameraError) -> Void
    
    private let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInteractive)
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MobileNet().model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                if let error = error {
                    print("Vision request error: \(error.localizedDescription)")
                }
                
                let prediction = self?.processClassification(for: request)
                DispatchQueue.main.async { self?.detectedObjectLabel.text = prediction }
            }
            
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load ML model: \(error)")
        }
    }()
    
    @IBOutlet weak var detectedObjectLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addApplicationEventObservers()
        startCaptureVideo()
    }
    
    deinit {
        removeApplicationEventObservers()
    }
    
    // MARK: - Background/Foreground observer methods
    
    private func addApplicationEventObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notifyApplicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notifyApplicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    private func removeApplicationEventObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Start/Stop capture video methods

    private func startCaptureVideo() {
        requestCameraPermission(completionBlock: { [weak self] in
            DispatchQueue.main.async { self?.showCameraPreview() }
            }, failedBlock: { [weak self] error in
                DispatchQueue.main.async { self?.showError(error) }
        })
    }
    
    private func stopCaptureVideo() {
        hideCameraPreview()
    }
    
    // MARK: - Camera permission methods
    
    private func requestCameraPermission(completionBlock: @escaping CompletionBlock,
                                         failedBlock: @escaping FailedBlock) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completionBlock()
        case .denied, .restricted:
            failedBlock(.cameraPermissionDenied)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    completionBlock()
                } else {
                    failedBlock(.cameraPermissionDenied)
                }
            }
        @unknown default:
            fatalError("Need to handle new status: \(status)")
        }
    }
    
    // MARK: - Show/Hide camera preview methods
    
    private func showCameraPreview() {
        do {
            try startCaptureSession()
            
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            cameraPreviewLayer?.frame = view.bounds
            cameraPreviewLayer?.videoGravity = .resizeAspectFill
            
            if let layer = cameraPreviewLayer {
                view.layer.insertSublayer(layer, at: 0)
            }
        } catch {
            guard let cameraError = error as? CameraError else { fatalError("Need to handle unexpected error: \(error)") }
            showError(cameraError)
        }
    }
    
    private func hideCameraPreview() {
        stopCaptureSession()
        
        cameraPreviewLayer?.removeFromSuperlayer()
        cameraPreviewLayer = nil
    }
    
    // MARK: - AVCaptureSession methods

    private func startCaptureSession() throws {
        guard let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device) else {
                throw CameraError.videoCaptureNotFound
        }

        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(videoDataOutput) {
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataQueue)
            session.addOutput(videoDataOutput)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    private func stopCaptureSession() {
        videoDataOutput.setSampleBufferDelegate(nil, queue: nil)
        session.stopRunning()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
    }
    
    // MARK: - Background/Foreground notification methods
    
    @objc private func notifyApplicationDidEnterBackground() {
        stopCaptureVideo()
    }
    
    @objc private func notifyApplicationWillEnterForeground() {
        startCaptureVideo()
    }
    
    // MARK: - Util methods
    
    private func showError(_ error: CameraError) {
        let alertError = error.toAlertControllerError()
        let alert = UIAlertController(title: alertError.title, message: alertError.message, preferredStyle: alertError.style)
        alertError.actions.forEach { alert.addAction($0) }
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvImageBuffer: pixelBuffer)
        let exifOrientation = UIDevice.current.exifOrientation()
        classify(image: image, orientation: exifOrientation)
    }
}

// MARK: - Classification methods

extension ViewController {
    
    private func classify(image: CIImage, orientation: CGImagePropertyOrientation) {
        let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print("Failed to perform classification: \(error.localizedDescription)")
        }
    }
    
    private func processClassification(for request: VNRequest) -> String {
        guard let results = request.results,
            let classifications = results as? [VNClassificationObservation],
            !classifications.isEmpty else {
                return "Nothing detected"
        }
        
        // return the best 3 results
        return classifications
            .prefix(3)
            .map { "[\(Int($0.confidence * 100))%] \($0.identifier)" }
            .joined(separator: "\n")
    }
}

