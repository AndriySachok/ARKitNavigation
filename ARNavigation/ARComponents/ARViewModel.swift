//
//  ARViewModel.swift
//  JetIQ
//
//  Created by Андрій on 22.09.2024.
//

import Foundation
import RealityKit
import ARKit
import simd
import Combine

class ARViewModel: UIViewController, ObservableObject, ARSessionDelegate {
    var model: ARModel?
    var updateMappingStatusPublisher = PassthroughSubject<ARFrame.WorldMappingStatus?, Never>()
    @Published var anchorCounter: Int = 0
    @Published var worldMappingStatus: ARFrame.WorldMappingStatus? {
        didSet {
            updateMappingStatusPublisher.send(worldMappingStatus)
        }
    }
    @Published var foundClosestAnchor = false
    
    var arView: ARView {
        model?.arView ?? ARView()
    }
    
    func startSessionDelegate() {
        model?.arView.session.delegate = self
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            print("Anchor added: \(anchor.identifier), type: \(type(of: anchor))")
            print("Position: \(anchor.transform.columns.3.x), \(anchor.transform.columns.3.y), \(anchor.transform.columns.3.z)")
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            print("Anchor removed: \(anchor.identifier), type: \(type(of: anchor))")
            print("Position: \(anchor.transform.columns.3.x), \(anchor.transform.columns.3.y), \(anchor.transform.columns.3.z)")
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.camera.trackingState == .normal {
            self.worldMappingStatus = arView.session.currentFrame?.worldMappingStatus
        }
    }
    
    func getHitTestPosition() -> simd_float4x4? {
        let results = arView.hitTest(arView.center, types: [.existingPlaneUsingExtent])
        if let result = results.first {
            print("Hit test successful at position: \(result.worldTransform.columns.3)")
            return result.worldTransform
        }
        print("No valid hit test results found. Anchor not added.")
        return nil
    }
    
    func calculateDistances() {
        arView.session.getCurrentWorldMap { worldMap, error in
            if let worldMap = worldMap {
                // Filter for custom path anchors
                let customPathAnchors = worldMap.anchors.compactMap { anchor in
                    return (anchor as? CustomAnchor)?.metadata.type == "path" ? anchor as? CustomAnchor : nil
                }

                for anchor in customPathAnchors {
                    let anchorPosition = anchor.transform
                    
                    let neighbors = self.findNeighbors(from: anchorPosition, to: customPathAnchors, number: anchor.metadata.pathData?.neighborNum ?? -1)
                    
                    let neighborIDs = neighbors.compactMap { $0.metadata.pathData?.id }

                    if var pathData = anchor.metadata.pathData {
                        pathData.neighborPathIds = neighborIDs
                        anchor.metadata.pathData = pathData
                    }
                }
                
                // Once modified, re-add the anchors (replacing the old ones in AR)
                for updatedAnchor in customPathAnchors {
                    self.arView.session.remove(anchor: updatedAnchor)
                    self.arView.session.add(anchor: updatedAnchor)
                }
                
                Task {
                    await self.visualizeAnchors(from: worldMap)
                }
            }
        }
    }
    
    func findNeighbors(from position: simd_float4x4, to allAnchors: [CustomAnchor], number: Int) -> [CustomAnchor] {
        let mainAnchorPosition = SIMD3(position.columns.3.x,
                                       position.columns.3.y,
                                       position.columns.3.z)
        
        let potentialNeighbors = allAnchors.filter { $0.transform != position }
        
        var anchorsWithDistances: [(anchor: CustomAnchor, distance: Float)] = potentialNeighbors.map { anchor in
            let anchorPosition = SIMD3(anchor.transform.columns.3.x,
                                       anchor.transform.columns.3.y,
                                       anchor.transform.columns.3.z)
            let distance = simd_distance(mainAnchorPosition, anchorPosition)
            return (anchor: anchor, distance: distance)
        }
        
        anchorsWithDistances.sort { $0.distance < $1.distance }
        
        let closestAnchors = anchorsWithDistances.prefix(number).map { $0.anchor }
        
        return Array(closestAnchors)
    }
    
    
    func findShortestDistance(userPosition: SIMD3<Float>, anchors: [CustomAnchor]) -> CustomAnchor? {
        guard !anchors.isEmpty else { return nil }

        var shortestDistance: Float? = nil
        var closestAnchor: CustomAnchor? = nil
        
        for anchor in anchors {
            let anchorPosition = SIMD3(anchor.transform.columns.3.x,
                                       anchor.transform.columns.3.y,
                                       anchor.transform.columns.3.z)
            
            let distance = simd_distance(userPosition, anchorPosition)
            
            if shortestDistance == nil || distance < shortestDistance! {
                shortestDistance = distance
                closestAnchor = anchor
            }
        }
        if closestAnchor != nil {
            foundClosestAnchor = true
        }
        return closestAnchor
    }
    
    func visualizeAnchors(from worldMap: ARWorldMap) async {
        print("visss\n")
        arView.scene.anchors.removeAll()
        let customAnchors = worldMap.anchors.compactMap { $0 as? CustomAnchor }
        
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let userPosition = SIMD3(cameraTransform.columns.3.x,
                                     cameraTransform.columns.3.y,
                                     cameraTransform.columns.3.z)
            let closestAnchor = findShortestDistance(userPosition: userPosition, anchors: customAnchors)
            
            for anchor in customAnchors {
                var textInfo: String = "-1"
                if let pathData = anchor.metadata.pathData {
                    textInfo = "P\(pathData.id):\(pathData.neighborPathIds)"
                }
                if let roomData = anchor.metadata.roomData {
                    textInfo = "R\(roomData.room_num)\n->\(roomData.closestPathId)"
                }
                
                let textMesh = MeshResource.generateText(
                    "\(textInfo)", // The number you want to visualize
                    extrusionDepth: 0.02, // Depth of the 3D text
                    font: .systemFont(ofSize: 0.2), // Font and size
                    containerFrame: .zero, // Frame for the text (if needed)
                    alignment: .center, // Center align the text
                    lineBreakMode: .byTruncatingTail // Line break mode (if needed)
                )
                
                let textMaterial = SimpleMaterial(color: anchor == closestAnchor ? .red : .yellow, isMetallic: false)
                let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
                
                let anchorEntity = AnchorEntity(world: anchor.transform)
                
                anchorEntity.addChild(textEntity)
                
                arView.scene.addAnchor(anchorEntity)
            }
        }
        
//        await drawPathBetweenAnchors(anchors: customAnchors, worldMap: worldMap)
    }
    
    func visualizePath(from worldMap: ARWorldMap, to roomNum: Int) async {
        print("visss\n")
        arView.scene.anchors.removeAll()
        let customAnchors = worldMap.anchors.compactMap { $0 as? CustomAnchor }
        let customPathAnchors = customAnchors.filter { anchor in
            return anchor.metadata.type == "path"
        }
        let roomAnchor = customAnchors.first(where: { $0.metadata.roomData?.room_num == roomNum })
        let customPathNodes = customPathAnchors.compactMap { $0.metadata.pathData }
        let roomNode = customAnchors.filter { anchor in
            return anchor.metadata.roomData?.room_num == roomNum
        }.first?.metadata.roomData
        
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let userPosition = SIMD3(cameraTransform.columns.3.x,
                                     cameraTransform.columns.3.y,
                                     cameraTransform.columns.3.z)
            let closestAnchor = findShortestDistance(userPosition: userPosition, anchors: customPathAnchors)
            let closestPathNode = closestAnchor?.metadata.pathData
            print("customAnchors: ",customAnchors.count)
            
            guard let closestPathNode = closestPathNode, let roomNode = roomNode else {
                print("Cannot construct navigation")
                return
            }
            let pathIds = NavigationModel.bfs(startPathNode: closestPathNode, roomNode: roomNode, pathNodes: customPathNodes)
            if let pathIds = pathIds {
                await drawPathBetweenAnchors(anchorsIds: pathIds, allAnchors: customAnchors, targetRoomNum: roomNum)
            }
            if let endPointEntity = await addEndpoint(), let roomAnchor = roomAnchor {
                let anchorEntity = AnchorEntity(world: roomAnchor.transform)
                anchorEntity.addChild(endPointEntity)
                self.arView.scene.addAnchor(anchorEntity)
            }
        }
    }
    
    func drawPathBetweenAnchors(anchorsIds: [Int], allAnchors: [CustomAnchor], targetRoomNum: Int) async {
        var pathAnchors = anchorsIds.compactMap { anchorId in
            return allAnchors.first(where: { $0.metadata.pathData?.id == anchorId })
        }
        if let roomAnchor = allAnchors.first(where: { $0.metadata.roomData?.room_num == targetRoomNum }) {
            pathAnchors.append(roomAnchor)
            print("room anchor added\n")
        }
        
        for i in 0..<pathAnchors.count - 1 {
            let startAnchor = pathAnchors[i]
            let endAnchor = pathAnchors[i + 1]

            if let arrowEntity = await addArrow(from: startAnchor.transform, to: endAnchor.transform) {
                let anchorEntity = AnchorEntity(world: startAnchor.transform)
                anchorEntity.addChild(arrowEntity)
                
                await MainActor.run {
                    self.arView.scene.addAnchor(anchorEntity)
                }
            }
        }
    }
    
    func addArrow(from startAnchor: simd_float4x4, to endAnchor: simd_float4x4, color: UIColor? = nil) async -> ModelEntity? {
        let usdzPath = "arrow.usdz"
        
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable? = nil
            
            cancellable = ModelEntity.loadModelAsync(named: usdzPath)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Failed to load arrow model with error: \(error)")
                        continuation.resume(returning: nil)
                    }
                    cancellable?.cancel()
                }, receiveValue: { arrowEntity in
                        if let color = color {
                            arrowEntity.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
                        }
                        
                        let start = simd_float3(startAnchor.columns.3.x, startAnchor.columns.3.y, startAnchor.columns.3.z)
                        let end = simd_float3(endAnchor.columns.3.x, endAnchor.columns.3.y, endAnchor.columns.3.z)
                        let direction = normalize(end - start)
                        
                        let rotation1 = simd_quatf(angle: .pi / 2, axis: SIMD3(1, 0, 0)) // Rotate 90 degrees around X-axis
                        let rotation2 = simd_quatf(from: SIMD3(1, 0, 0), to: direction)  // Rotate to align with direction
                        
                        arrowEntity.transform.rotation = rotation2 * rotation1
                        continuation.resume(returning: arrowEntity)
                    cancellable?.cancel()
                })
        }
    }
    
    func addEndpoint() async -> ModelEntity? {
        let usdzPath = "diamond.usdz"
        
        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable? = nil
            
            cancellable = ModelEntity.loadModelAsync(named: usdzPath)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Failed to load arrow model with error: \(error)")
                        continuation.resume(returning: nil)
                    }
                    cancellable?.cancel()
                }, receiveValue: { arrowEntity in
                    continuation.resume(returning: arrowEntity)
                    cancellable?.cancel()
                })
        }
    }
}
