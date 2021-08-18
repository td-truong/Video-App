//
//  CMTime+Exts.swift
//  VideoApp
//
//  Created by Duy Truong on 18/08/2021.
//

import CoreMedia

extension CMTime {
    static func +(lhs: CMTime, rhs: CMTime) -> CMTime {
        return CMTimeAdd(lhs, rhs)
    }
    
    static func +=(lhs: inout CMTime, rhs: CMTime) {
        lhs = CMTimeAdd(lhs, rhs)
    }
    
    static func -(lhs: CMTime, rhs: CMTime) -> CMTime {
        return CMTimeSubtract(lhs, rhs)
    }
    
    static func /(lhs: CMTime, divisor: Int32) -> CMTime {
        return CMTimeMultiplyByRatio(lhs, multiplier: 1, divisor: divisor)
    }
    
    static func <(lhs: CMTime, rhs: CMTime) -> Bool {
        return CMTimeCompare(lhs, rhs) == -1
    }
}
