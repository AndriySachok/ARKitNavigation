//
//  ARModel.swift
//  JetIQ
//
//  Created by Андрій on 22.09.2024.
//

import Foundation
import RealityKit
import ARKit

class ARModel {
    private(set) var arView: ARView
    
    init() {
        arView = ARView(frame: .zero)
        setupArView(options: [.resetTracking, .removeExistingAnchors])
    }
    
    deinit {
        arView.session.pause()
        print("deinnited\n")
    }
    
    func setupArView(options: ARSession.RunOptions, worldMap: ARWorldMap? = nil) {
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            config.sceneReconstruction = .meshWithClassification
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics = [.personSegmentationWithDepth]
        }
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.environment.sceneUnderstanding.options.insert([.occlusion, .physics])
        if worldMap != nil {
            config.initialWorldMap = worldMap
        }
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        arView.session.run(config, options: options)
    }
    
    func addAnchor(position: simd_float4x4, metadata: CustomAnchor.AnchorMetadata, completion: (() -> ())?) {
        
        let customAnchor = CustomAnchor(name: "CustomAnchor", transform: position, metadata: metadata)
        
        arView.session.add(anchor: customAnchor)
        
        
        var text = ""
        if let path = metadata.pathData {
            text = "P\(path.id):\(path.neighborNum)"
        } else if let room = metadata.roomData {
            text = "R\(room.room_num)\n->\(room.closestPathId)"
        }
        
        
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.02,
            font: .systemFont(ofSize: 0.2),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )
        let textMaterial = SimpleMaterial(color: .yellow, isMetallic: false) // Customize the material
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        let anchorEntity = AnchorEntity(world: customAnchor.transform)
        anchorEntity.addChild(textEntity)
        
        arView.scene.addAnchor(anchorEntity)
        completion?()
        print("Custom anchor and visual entity added successfully.")
    }
    
    
}
