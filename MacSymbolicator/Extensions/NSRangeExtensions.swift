//
//  NSRangeExtensions.swift
//  MacSymbolicator
//

import Foundation

extension NSRange {
    /*
     r1(location: 10, length: 20) -> upperBound: 30
     r2(location: 20, length: 40) -> upperBound: 60
     intersection: (location: 20, length: 10)
     => [(location: 10, length: 10)]

     r1(location: 10, length: 20) -> upperBound: 30
     r2(location: 20, length: 5) -> upperBound: 25
     intersection: (location: 20, length: 5)
     => [(location: 10, length: 10), (location: 25, length: 5)]

     r1(location: 20, length: 40) -> upperBound: 60
     r2(location: 10, length: 40) -> upperBound: 50
     => [(location: 50, length: 10)]
     */
    func subtracting(_ range2: NSRange) -> [SubtractedNSRange] {
        let range1 = self

        var ranges: [SubtractedNSRange] = []

        guard range2.length != 0, let intersection = range1.intersection(range2) else {
            ranges.append(.init(range: range1, shortenedFromStart: false, shortenedFromEnd: false))
            return ranges
        }

        if range1.location < intersection.location {
            let newRange = NSRange(location: range1.location, length: intersection.location - range1.location)
            ranges.append(.init(range: newRange, shortenedFromStart: false, shortenedFromEnd: true))
        }

        if range1.location >= intersection.upperBound {
            ranges.append(.init(range: range1, shortenedFromStart: false, shortenedFromEnd: false))
        } else if intersection.upperBound < range1.upperBound {
            let newRange = NSRange(
                location: intersection.upperBound,
                length: range1.upperBound - intersection.upperBound
            )
            ranges.append(.init(range: newRange, shortenedFromStart: true, shortenedFromEnd: false))
        }

        return ranges
    }

    /// Assumes ranges are non-overlapping and non-contiguous
    func subtracting(_ ranges: [NSRange]) -> [SubtractedNSRange] {
        var rangesToSubtract = ranges

        var result: [SubtractedNSRange] = [.init(
            range: self,
            shortenedFromStart: false,
            shortenedFromEnd: false
        )]

        while !rangesToSubtract.isEmpty {
            let rangeToSubtract = rangesToSubtract.removeFirst()

            result = result.flatMap {
                $0.subtracting(rangeToSubtract)
            }
        }

        return result
    }

    func split() -> (NSRange, NSRange)? {
        guard location != NSNotFound, length > 1 else {
            return nil
        }

        let splitPoint = Int(ceil(Double(length) / 2))

        return (
            NSRange(location: location, length: splitPoint),
            NSRange(location: location + splitPoint, length: length - splitPoint)
        )
    }
}

struct SubtractedNSRange: Equatable, Sendable {
    let range: NSRange
    let shortenedFromStart: Bool
    let shortenedFromEnd: Bool

    func subtracting(_ range2: NSRange) -> [SubtractedNSRange] {
        range.subtracting(range2).map {
            SubtractedNSRange(
                range: $0.range,
                shortenedFromStart: shortenedFromStart || $0.shortenedFromStart,
                shortenedFromEnd: shortenedFromEnd || $0.shortenedFromEnd
            )
        }
    }
}
