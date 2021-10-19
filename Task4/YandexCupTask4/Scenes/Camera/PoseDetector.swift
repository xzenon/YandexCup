//
//  PoseDetector.swift
//  YandexCupTask4
//
//  Created by Xenon on 17.10.2021.
//

import Foundation
import AVFoundation
import Vision
import Combine

enum PoseJointPairType {
    case rootNeck
    case rightAnkleKnee
    case rightKneeHip
    case rightWristElbow
    case rightElbowShoulder
    case leftAnkleKnee
    case leftKneeHip
    case leftWristElbow
    case leftElbowShoulder
}

struct Pose {
    var jointPairs: [PoseJointPair]
    var confidence: Float
    var isCorrect: Bool {
        return confidence > 0.5
    }
}

struct PoseJointPair {
    var type: PoseJointPairType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var isCorrect: Bool
    
    init(type: PoseJointPairType, startPoint: CGPoint, endPoint: CGPoint, isCorrect: Bool = false) {
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.isCorrect = isCorrect
    }
    
    var angle: Int {
        let radians = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        return Int(radians * 180 / .pi)
    }
    
    var supplementaryAngle: Int {
        return 180 - angle
    }
    
    var invalidAngle: Bool {
        return angle > 180 || angle < 0
    }
    
    func angle(_ supplementary: Bool) -> Int {
        return supplementary ? supplementaryAngle : angle
    }
}

protocol PoseDetectable {
    func detect(with bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Pose?
}

class PoseDetector: PoseDetectable {
    
    internal var jointPairs: [PoseJointPairType: PoseJointPair] = [:]
    
    func prepare(with bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> [PoseJointPairType: PoseJointPair] {
        let detectedParts = bodyParts.filter{ $0.value.confidence > 0.2 }
        var detectedPairs: [PoseJointPairType: PoseJointPair] = [:]
        
        if let rightAnkle = detectedParts[.rightAnkle]?.location, let rightKnee = detectedParts[.rightKnee]?.location {
            detectedPairs[.rightAnkleKnee] = PoseJointPair(type: .rightAnkleKnee, startPoint: rightAnkle, endPoint: rightKnee)
        }
        if let rightKnee = detectedParts[.rightKnee]?.location, let rightHip = detectedParts[.rightHip]?.location {
            detectedPairs[.rightKneeHip] = PoseJointPair(type: .rightKneeHip, startPoint: rightKnee, endPoint: rightHip)
        }
        if let rightWrist = detectedParts[.rightWrist]?.location, let rightElbow = detectedParts[.rightElbow]?.location {
            detectedPairs[.rightWristElbow] = PoseJointPair(type: .rightWristElbow, startPoint: rightWrist, endPoint: rightElbow)
        }
        if let rightElbow = detectedParts[.rightElbow]?.location, let rightShoulder = detectedParts[.rightShoulder]?.location {
            detectedPairs[.rightElbowShoulder] = PoseJointPair(type: .rightElbowShoulder, startPoint: rightElbow, endPoint: rightShoulder)
        }
        if let leftAnkle = detectedParts[.leftAnkle]?.location, let leftKnee = detectedParts[.leftKnee]?.location {
            detectedPairs[.leftAnkleKnee] = PoseJointPair(type: .leftAnkleKnee, startPoint: leftAnkle, endPoint: leftKnee)
        }
        if let leftKnee = detectedParts[.leftKnee]?.location, let leftHip = detectedParts[.leftHip]?.location {
            detectedPairs[.leftKneeHip] = PoseJointPair(type: .leftKneeHip, startPoint: leftKnee, endPoint: leftHip)
        }
        if let leftWrist = detectedParts[.leftWrist]?.location, let leftElbow = detectedParts[.leftElbow]?.location {
            detectedPairs[.leftWristElbow] = PoseJointPair(type: .leftWristElbow, startPoint: leftWrist, endPoint: leftElbow)
        }
        if let leftElbow = detectedParts[.leftElbow]?.location, let leftShoulder = detectedParts[.leftShoulder]?.location {
            detectedPairs[.leftElbowShoulder] = PoseJointPair(type: .leftElbowShoulder, startPoint: leftElbow, endPoint: leftShoulder)
        }
        if let root = detectedParts[.root]?.location, let neck = detectedParts[.neck]?.location {
            detectedPairs[.rootNeck] = PoseJointPair(type: .rootNeck, startPoint: root, endPoint: neck)
        }
        return detectedPairs
    }
    
    func detect(with bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Pose? {
        return nil
    }
}


class PlankPoseDetector: PoseDetector {
    
    override func detect(with bodyParts: [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]) -> Pose? {
        jointPairs = prepare(with: bodyParts)
        
        guard let rootNeck = jointPairs[.rootNeck], !rootNeck.invalidAngle else { return nil }
        let supplementary = rootNeck.angle > 90
        
        let maxPoseConfidenceScore = 18
        var poseConfidenceScore = 0
        
        //check body angle
        if rootNeck.angle(supplementary) < 45 {
            jointPairs[.rootNeck]?.isCorrect = true
            poseConfidenceScore += 4
        }
        
        //check arms
        if let leftElbowShoulder = jointPairs[.leftElbowShoulder],
           !leftElbowShoulder.invalidAngle,
           leftElbowShoulder.angle(supplementary) > 70,
           leftElbowShoulder.angle(supplementary) < 110 {
            jointPairs[.leftElbowShoulder]?.isCorrect = true
            poseConfidenceScore += 2
        }
        
        if let rightElbowShoulder = jointPairs[.rightElbowShoulder],
           !rightElbowShoulder.invalidAngle,
           rightElbowShoulder.angle(supplementary) > 70,
           rightElbowShoulder.angle(supplementary) < 110 {
            jointPairs[.rightElbowShoulder]?.isCorrect = true
            poseConfidenceScore += 2
        }
        
        if let rightWristElbow = jointPairs[.rightWristElbow], !rightWristElbow.invalidAngle,
           let rightKneeHip = jointPairs[.rightKneeHip], !rightKneeHip.invalidAngle,
           rightWristElbow.startPoint.y < rightKneeHip.startPoint.y {
            jointPairs[.rightWristElbow]?.isCorrect = true
            poseConfidenceScore += 3
        }
        
        if let leftWristElbow = jointPairs[.leftWristElbow], !leftWristElbow.invalidAngle,
           let leftKneeHip = jointPairs[.leftKneeHip], !leftKneeHip.invalidAngle,
           leftWristElbow.startPoint.y < leftKneeHip.startPoint.y {
            jointPairs[.leftWristElbow]?.isCorrect = true
            poseConfidenceScore += 3
        }
        
        //check legs
        if let rightAnkleKnee = jointPairs[.rightAnkleKnee],
           !rightAnkleKnee.invalidAngle,
           rightAnkleKnee.angle(supplementary) < 45 {
            jointPairs[.rightAnkleKnee]?.isCorrect = true
            poseConfidenceScore += 1
        }
        
        if let leftAnkleKnee = jointPairs[.leftAnkleKnee],
           !leftAnkleKnee.invalidAngle,
           leftAnkleKnee.angle(supplementary) < 45 {
            jointPairs[.leftAnkleKnee]?.isCorrect = true
            poseConfidenceScore += 1
        }
        
        if let rightKneeHip = jointPairs[.rightKneeHip],
           !rightKneeHip.invalidAngle,
           rightKneeHip.angle(supplementary) < 45 {
            jointPairs[.rightKneeHip]?.isCorrect = true
            poseConfidenceScore += 1
        }
        
        if let leftKneeHip = jointPairs[.leftKneeHip],
           !leftKneeHip.invalidAngle,
           leftKneeHip.angle(supplementary) < 45 {
            jointPairs[.leftKneeHip]?.isCorrect = true
            poseConfidenceScore += 1
        }
        
        let poseConfidence = Float(poseConfidenceScore)/Float(maxPoseConfidenceScore)
        return Pose(jointPairs: Array(jointPairs.values), confidence: poseConfidence)
    }
}
