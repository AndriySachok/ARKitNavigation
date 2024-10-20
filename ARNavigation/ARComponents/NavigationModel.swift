//
//  NavigationModel.swift
//  JetIQ
//
//  Created by Андрій on 29.09.2024.
//

import Foundation
import ARKit

class NavigationModel {
    
    static func bfs(startPathNode: PathNode, roomNode: RoomNode, pathNodes: [PathNode]) -> [Int]? {
        var queue: [PathNode] = [startPathNode]
        var visited: Set<Int> = [startPathNode.id]
        var parentMap: [Int: Int] = [:]

        while !queue.isEmpty {
            let currentNode = queue.removeFirst()

            if roomNode.closestPathId == currentNode.id {
                return constructPath(from: startPathNode.id, to: currentNode.id, parentMap: parentMap)
            }

            for neighborId in currentNode.neighborPathIds {
                if !visited.contains(neighborId) {
                    if let neighborNode = pathNodes.first(where: { $0.id == neighborId }) {
                        queue.append(neighborNode)
                        visited.insert(neighborId)
                        parentMap[neighborId] = currentNode.id
                    }
                }
            }
        }

        return nil
    }

    static private func constructPath(from startId: Int, to endId: Int, parentMap: [Int: Int]) -> [Int] {
        var path: [Int] = []
        var currentId: Int? = endId

        while let id = currentId {
            path.insert(id, at: 0)
            currentId = parentMap[id]
        }

        return path
    }
    
}
