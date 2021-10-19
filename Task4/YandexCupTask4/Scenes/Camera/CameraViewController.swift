//
//  CameraViewController.swift
//  YandexCupTask4
//
//  Created by Xenon on 17.10.2021.
//

import Foundation
import UIKit
import AVFoundation
import Vision

enum DetectionState {
    case none
    case detected(pose: Pose)
}

final class CameraViewController: UIViewController {
    
    var delegate: RecorderDelegate?
    
    private var cameraSession: AVCaptureSession?
    private var cameraView: CameraView { view as! CameraView }
    private var cameraPosition: AVCaptureDevice.Position = .front
    private let cameraQueue = DispatchQueue(label: "CameraOutput", qos: .userInteractive)
    private let overlayView = OverlayView()
    private var deviceOrientation = UIDevice.current.orientation
    
    private let sequenceHandler = VNSequenceRequestHandler()
    private let poseDetectors: [PoseDetector] = [PlankPoseDetector()]
    private var detectionState: DetectionState = .none
    private let detectionTreshold: TimeInterval = 2.0
    private var detectionDuration: TimeInterval = 0.0
    private var lastDetectionDate: Date?
    private var timer: Timer?
    private let timerInterval: TimeInterval = 1.0
    
    //UI elements
        
    private var doneButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.layer.cornerRadius = 5
        button.contentEdgeInsets =  UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(UIColor.black.withAlphaComponent(0.3), for: .highlighted)
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(doneButtonDidPress(button:)), for: .touchUpInside)
        return button
    }()
    
    private var durationButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.layer.cornerRadius = 5
        button.contentEdgeInsets =  UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(UIColor.black.withAlphaComponent(0.3), for: .highlighted)
        button.setTitle("00:00", for: .normal)
        button.addTarget(self, action: #selector(durationButtonDidPress(button:)), for: .touchUpInside)
        return button
    }()
    
    private var cameraButton: UIButton = {
        let button = UIButton()
        button.clipsToBounds = true
        button.layer.cornerRadius = 5
        button.contentEdgeInsets =  UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: "flip-icon")?.withTintColor(.black), for: .normal)
        button.setImage(UIImage(named: "flip-icon")?.withTintColor(UIColor.black.withAlphaComponent(0.3)), for: .highlighted)
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.addTarget(self, action: #selector(cameraButtonDidPress(button:)), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func loadView() {
        view = CameraView()
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        
        //detected pose overlay view
        view.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        overlayView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        //"Camera" button
        view.addSubview(cameraButton)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
        cameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        cameraButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        cameraButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        //"Done" button
        view.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        
        //"Duration" button
        view.addSubview(durationButton)
        durationButton.translatesAutoresizingMaskIntoConstraints = false
        durationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        durationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        
        //timer
        timer = Timer(timeInterval: timerInterval, target: self, selector: #selector(timerDidFire(timer:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopCamera()
        timer?.invalidate()
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
            DispatchQueue.main.async(execute: {
                self?.updateVideoOrientation()
            })
        })
    }
    
    //MARK: - Camera
    
    private func startCamera() {
        do {
            if cameraSession == nil {
                try prepareAVSession()
                cameraView.previewLayer.session = cameraSession
                cameraView.previewLayer.videoGravity = .resizeAspectFill
            }
            cameraSession?.startRunning()
        } catch {
            print("Camera error: \(error.localizedDescription)")
        }
    }
    
    private func stopCamera() {
        cameraSession?.stopRunning()
        cameraSession = nil
    }
    
    private func prepareAVSession() throws {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition)
        else { return }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice)
        else { return }
        
        guard session.canAddInput(deviceInput)
        else { return }
        
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.alwaysDiscardsLateVideoFrames = true

        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            dataOutput.setSampleBufferDelegate(self /*delegate*/, queue: cameraQueue)
        } else { return }
        
        session.commitConfiguration()
        cameraSession = session
    }
    
    private func updateVideoOrientation() {
        guard cameraView.previewLayer.connection!.isVideoOrientationSupported else {
            print("Error: isVideoOrientationSupported is false")
            return
        }
        deviceOrientation = UIDevice.current.orientation
        cameraView.previewLayer.frame = view.layer.bounds
        cameraView.previewLayer.connection?.videoOrientation = deviceOrientation.videoOrientation ?? .portrait
        cameraView.previewLayer.removeAllAnimations()
    }
    
    // MARK: - Actions

    @objc
    private func doneButtonDidPress(button _: UIButton) {
        guard detectionDuration > 0 else {
            dismiss(animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "Save this record", message: "Do you want to save currently recorded duration?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            self.delegate?.addNew(record: Record(duration: self.detectionDuration, date: Date()))
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    @objc
    private func durationButtonDidPress(button _: UIButton) {
        let alert = UIAlertController(title: "Reset", message: "Do you want to reset currently recorded duration?", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Reset", style: .default, handler: { _ in
            self.detectionDuration = 0.0
            self.durationButton.setTitle(self.detectionDuration.stringFromTimeInterval(), for: .normal)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    @objc
    private func cameraButtonDidPress(button _: UIButton) {
        stopCamera()
        cameraPosition = (cameraPosition == .front ? .back : .front)
        startCamera()
    }

    @objc
    private func timerDidFire(timer: Timer) {
        handleState()
    }
    
    // MARK: - State handling
    
    private func setState(to newState: DetectionState) {
        switch (detectionState, newState) {
        case (.none, .detected(let pose)):
            guard pose.isCorrect else { return }
            lastDetectionDate = Date()
            AudioServicesPlayAlertSound(SystemSoundID(1117))
        case (.detected, .none):
            lastDetectionDate = nil
            AudioServicesPlayAlertSound(SystemSoundID(1114))
        case (.detected, .detected(let newPose)) where newPose.isCorrect:
            lastDetectionDate = Date()
        default:
            break
        }
        detectionState = newState
    }
    
    private func handleState() {
        switch detectionState {
        case .none:
            durationButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            overlayView.update(with: nil)
        case .detected(let pose):
            durationButton.backgroundColor = pose.isCorrect ? UIColor.green.withAlphaComponent(0.7) : UIColor.orange.withAlphaComponent(0.7)
            if let currentLastDetectionDate = lastDetectionDate {
                if Date().timeIntervalSince(currentLastDetectionDate) < detectionTreshold {
                    detectionDuration += timerInterval
                    DispatchQueue.main.async { [weak self] in
                        self?.overlayView.update(with: pose, self?.cameraPosition)
                    }
                } else {
                    setState(to: .none)
                }
            }
        }
        durationButton.setTitle(detectionDuration.stringFromTimeInterval(), for: .normal)
    }
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let humanBodyRequest = VNDetectHumanBodyPoseRequest(completionHandler: handleBodyPose)
        do {
            try sequenceHandler.perform([humanBodyRequest],
                                        on: sampleBuffer,
                                        orientation: CGImagePropertyOrientation(frontCamera: cameraPosition == .front, deviceOrientation: deviceOrientation))
        } catch {
            print("VNDetectHumanBodyPoseRequest error: \(error.localizedDescription)")
        }
    }
    
    func handleBodyPose(request: VNRequest, error: Error?) {
        guard let bodyPoseResults = request.results as? [VNHumanBodyPoseObservation] else { return }
        guard let bodyParts = try? bodyPoseResults.first?.recognizedPoints(.all) else { return }
        
        if let detectedPose = poseDetectors
            .compactMap({ $0.detect(with: bodyParts) })
            .sorted(by: { $0.confidence > $1.confidence })
            .first {
            //print("Detected pose confidence: \(detectedPose.confidence)")
            setState(to: .detected(pose: detectedPose))
        } else {
            //print("Pose not detected")
            setState(to: .none)
        }
    }
}
