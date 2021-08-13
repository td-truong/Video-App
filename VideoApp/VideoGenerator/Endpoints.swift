//
//  Endpoints.swift
//  VideoApp
//
//  Created by Machintosh on 13/08/2021.
//

import Foundation

enum Endpoints {
    static let mergeVideoDirectory = FileManager.default.documentURL.appendingPathComponent("merge-video", isDirectory: true)
    static let videoGen = mergeVideoDirectory.appendingPathComponent("video-gen").appendingPathExtension("mov")
    static let videoMerged = mergeVideoDirectory.appendingPathComponent("video-merged").appendingPathExtension("mov")
}

extension FileManager {
    var documentURL: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
