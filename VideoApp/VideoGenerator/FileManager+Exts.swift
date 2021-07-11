//
//  FileManager+Exts.swift
//  VideoApp
//
//  Created by Duy Truong on 11/07/2021.
//

import Foundation

extension FileManager {
    static func generateOutputURL(prefix: String = "") -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputDirectory = documentURL
        let outputURL = outputDirectory
            .appendingPathComponent("\(prefix)\(UUID().uuidString)")
            .appendingPathExtension("mov")
        return outputURL
    }
}
