//
//  Interactor.swift
//  ARNavigation
//
//  Created by Андрій on 20.10.2024.
//

import Foundation
import RealityKit
import ARKit
import Combine

class Interactor: ObservableObject {
    let arViewModel: ARViewModel
    var updatePublisher = PassthroughSubject<Void, Never>()
    var cancellableForMappingStatus: AnyCancellable?
    @Published var creationAction: CreationActions? = nil {
        didSet {
            guard let action = creationAction else { return }
            manageCreationAction(action: action)
        }
    }
    @Published var roomNumber: String = ""
    @Published var roomToFind: Int?
    @Published var savedMapUrl: URL? {
        didSet {
            print("SavedURL: ",savedMapUrl)
            self.updatePublisher.send()
        }
    }
    @Published var selectedMapURL: URL? {
        didSet {
            arViewModel.arView.session.pause()
            if let selectedUrl = selectedMapURL {
                if let worldMap = ARMapManager.shared.loadWorldMap(from: selectedUrl) {
                    arViewModel.model?.setupArView(options: [.resetTracking], worldMap: worldMap)
                    print("Successfully loaded ARWorldMap")
                    print("Anchors: ", worldMap.anchors.count)
                } else {
                    print("Failed to load ARWorldMap, starting new session.")
                    arViewModel.model?.setupArView(options: [.resetTracking, .removeExistingAnchors])
                }
            }
        }
    }
    
    init(viewModel: ARViewModel) {
        self.arViewModel = viewModel
        cancellableForMappingStatus = arViewModel.updateMappingStatusPublisher.sink(receiveValue: { [weak self] newMappingStatus in
            if let room = self?.roomToFind, newMappingStatus == .mapped, !(self?.arViewModel.foundClosestAnchor ?? false) {
                print("NAVIGATE!!!")
                self?.navigate(to: room)
            }
        })
    }
    
    private func manageCreationAction(action: CreationActions) {
        switch action {
        case .setPath1:
            createPathAnchor(with: 1)
        case .setPath2:
            createPathAnchor(with: 2)
        case .setPath3:
            createPathAnchor(with: 3)
        case .addRoom:
            createRoomAnchor(with: roomNumber)
        case .findNeighbors:
            arViewModel.calculateDistances()
        case .saveMap:
            saveMap()
        }
        
        creationAction = nil
    }
    
    private func createPathAnchor(with adjacentNum: Int) {
        let pathData = PathNode(id: arViewModel.anchorCounter, neighborNum: adjacentNum, neighborPathIds: [])
        let metadata = CustomAnchor.AnchorMetadata(type: "path", pathData: pathData)
        
        if let position = arViewModel.getHitTestPosition() {
            arViewModel.model?.addAnchor(position: position, metadata: metadata) {
                self.arViewModel.anchorCounter += 1
            }
        }
    }
    
    private func createRoomAnchor(with number: String) {
        guard let room = Int(number) else {
            print("Wrong room number")
            return
        }
        if let position = arViewModel.getHitTestPosition() {
            arViewModel.model?.arView.session.getCurrentWorldMap { worldMap, error in
                if let worldMap = worldMap {
                    let customPathAnchors = worldMap.anchors.compactMap { anchor in
                        if let customAnchor = anchor as? CustomAnchor, customAnchor.metadata.type == "path" {
                            return customAnchor
                        }
                        return nil
                    }
                    let neighbor = self.arViewModel.findNeighbors(from: position, to: customPathAnchors, number: 1)

                    if let closestPathAnchorId = neighbor.first?.metadata.pathData?.id {
                        print("found closest anchor")
                        let roomData = RoomNode(room_num: room, closestPathId: closestPathAnchorId)
                        let metadata = CustomAnchor.AnchorMetadata(type: "room", roomData: roomData)
                        
                        self.arViewModel.model?.addAnchor(position: position, metadata: metadata) {
                            self.roomNumber = ""
                        }
                    }
                    
                }
            }
        }
    }
    
    private func saveMap() {
        print("HERHEHER\n")
        arViewModel.model?.arView.session.getCurrentWorldMap { worldMap, error in
            if let worldMap = worldMap {
                let url = ARMapManager.shared.saveWorldMap(worldMap: worldMap)
                print("World map saved.")
                self.savedMapUrl = url
            } else if let error = error {
                print("Error retrieving ARWorldMap: \(error.localizedDescription)")
            }
        }
    }
    
    func navigate(to room: Int) {
        if selectedMapURL != nil, arViewModel.worldMappingStatus == .mapped, !arViewModel.foundClosestAnchor {
            arViewModel.arView.session.getCurrentWorldMap { worldMap, error in
                if let worldMap = worldMap {
                    Task {
                        await self.arViewModel.visualizePath(from: worldMap, to: room)
                    }
                }
            }
        }
    }
    
    func setARView() -> ARView {
        let arView = ARModel()
        arViewModel.model = arView
        arViewModel.startSessionDelegate()
        return arViewModel.arView
    }
    func killARView() {
        arViewModel.model = nil
    }
}

enum CreationActions {
    case setPath1
    case setPath2
    case setPath3
    case addRoom
    case findNeighbors
    case saveMap
}
