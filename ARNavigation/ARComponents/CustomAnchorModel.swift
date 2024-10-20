//
//  CustomAnchorModel.swift
//  JetIQ
//
//  Created by Андрій on 22.09.2024.
//

import Foundation
import ARKit

struct PathNode: Codable {
    var id: Int
    var neighborNum: Int
    var neighborPathIds: [Int]
}

struct RoomNode: Codable {
    var room_num: Int
    var closestPathId: Int
}

class CustomAnchor: ARAnchor {
    
    static override var supportsSecureCoding: Bool {
        return true
    }
    
    struct AnchorMetadata: Codable {
        var type: String
        var pathData: PathNode?
        var roomData: RoomNode?
    }

    var metadata: AnchorMetadata

    init(name: String, transform: simd_float4x4, metadata: AnchorMetadata) {
        self.metadata = metadata
        super.init(name: name, transform: transform)
    }

    required init(anchor: ARAnchor) {
        let customAnchor = anchor as? CustomAnchor
        self.metadata = customAnchor?.metadata ?? AnchorMetadata(type: "")
        super.init(anchor: anchor)
    }

    required init?(coder: NSCoder) {
        let allowedClasses: [AnyClass] = [NSString.self, NSNumber.self, NSArray.self]

        guard let type = coder.decodeObject(of: NSString.self, forKey: "type") as String? else {
            return nil
        }
        
        var pathData: PathNode?
        var roomData: RoomNode?
        
        if type == "path" {
            let pathId = coder.decodeInteger(forKey: "pathId")
            let neighborNum = coder.decodeInteger(forKey: "neighborNum")
            let neighborPathIds = coder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: "neighborPathIds") as? [Int] ?? []
            
            pathData = PathNode(id: pathId, neighborNum: neighborNum, neighborPathIds: neighborPathIds)
            
        } else if type == "room" {
            let roomNum = coder.decodeInteger(forKey: "room_num")
            let closestPathId = coder.decodeInteger(forKey: "closestPathId")
            
            roomData = RoomNode(room_num: roomNum, closestPathId: closestPathId)
        }
        self.metadata = AnchorMetadata(type: type, pathData: pathData, roomData: roomData)
        super.init(coder: coder)
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        coder.encode(metadata.type, forKey: "type")
        
        if let path = metadata.pathData {
            coder.encode(path.id, forKey: "pathId")
            coder.encode(path.neighborNum, forKey: "neighborNum")
            coder.encode(path.neighborPathIds, forKey: "neighborPathIds")
        }
        
        if let room = metadata.roomData {
            coder.encode(room.room_num, forKey: "room_num")
            coder.encode(room.closestPathId, forKey: "closestPathId")
        }
    }
}



