//
//  ExportSessionHelper.swift
//  VideoApp
//
//  Created by Duy Truong on 17/08/2021.
//

import AVFoundation

enum ExportSessionError: Error {
    case initFailure
}

class ExportSessionHelper {
    
    static func export(asset: AVAsset,
                       presetName: String = AVAssetExportPresetHighestQuality,
                       outputFileType: AVFileType = .mov,
                       outputURL: URL,
                       videoComposition: AVVideoComposition? = nil,
                       onSuccess: @escaping () -> Void,
                       onError: ((Error) -> Void)? = nil) {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            onError?(ExportSessionError.initFailure)
            return
        }
        
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true
        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                onSuccess()
            } else if let error = exportSession.error {
                onError?(error)
            }
        }
    }
    
}
