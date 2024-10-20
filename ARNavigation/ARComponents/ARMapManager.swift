//
//  ARMapManager.swift
//  JetIQ
//
//  Created by Андрій on 21.09.2024.
//

import Foundation
import ARKit

class ARMapManager {
    static let shared = ARMapManager()
    
    private init() {}
    
    func loadWorldMap(from fileURL: URL) -> ARWorldMap? {
        do {
            let data = try Data(contentsOf: fileURL)
            let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
            
            if let customAnchors = worldMap?.anchors.filter({ $0 is CustomAnchor }) as? [CustomAnchor] {
                print("Number of custom anchors: \(customAnchors.count)")
                for anchor in customAnchors {
                    if let pathData = anchor.metadata.pathData {
                        print("path -> \(pathData)")
                    } else if let roomData = anchor.metadata.roomData {
                        print("room -> \(roomData)")
                    }
                }
            } else {
                print("No custom anchors found or world map is nil.")
            }
            
            return worldMap
        } catch {
            print("Failed to load or unarchive ARWorldMap: \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveWorldMap(worldMap: ARWorldMap) -> URL? {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            let fileName = "ARWorldMap.dat"
            if let fileURL = getDocumentsDirectory()?.appendingPathComponent(fileName) {
                try data.write(to: fileURL)
                print("WorldMap saved at: \(fileURL)")
                return fileURL
            }
        } catch {
            print("Failed to archive world map: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func getDocumentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
