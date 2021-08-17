//
//  Endpoints.swift
//  VideoApp
//
//  Created by Duy Truong on 13/08/2021.
//

import Foundation

enum Endpoints {
    static let mergeVideoDirectory = FileManager.default.documentURL
        .appendingPathComponent("merge-video", isDirectory: true)
    static let videoCombined = mergeVideoDirectory
        .appendingPathComponent("video-combined")
        .appendingPathExtension("mov")
    static let videoMerged = mergeVideoDirectory
        .appendingPathComponent("video-merged")
        .appendingPathExtension("mov")
    static let videoCropped = FileManager.default.documentURL
        .appendingPathComponent("video-cropped")
        .appendingPathExtension("mov")
}

extension FileManager {
    var documentURL: URL {
        return urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
