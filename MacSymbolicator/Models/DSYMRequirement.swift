//
//  DSYMRequirement.swift
//  MacSymbolicator
//

import Foundation

struct DSYMRequirements: Equatable, Hashable, Sendable {
    let recommendedDSYMs: [BinaryUUID: DSYMRequirement]
    let optionalDSYMs: [BinaryUUID: DSYMRequirement]

    let sortedDSYMs: [DSYMRequirement]
    let expectedUUIDs: Set<BinaryUUID>

    init(recommendedDSYMs: Set<DSYMRequirement>, optionalDSYMs: Set<DSYMRequirement>) {
        // We might have an item in both recommended/optional, in which case we prefer 'recommended'
        let optionalDSYMs = optionalDSYMs.subtracting(recommendedDSYMs)

        var mappedRecommendedDSYMs: [BinaryUUID: DSYMRequirement] = [:]
        for dsym in recommendedDSYMs {
            mappedRecommendedDSYMs[dsym.uuid] = dsym
        }
        self.recommendedDSYMs = mappedRecommendedDSYMs

        var mappedOptionalDSYMs: [BinaryUUID: DSYMRequirement] = [:]
        for dsym in optionalDSYMs {
            mappedOptionalDSYMs[dsym.uuid] = dsym
        }
        self.optionalDSYMs = mappedOptionalDSYMs

        sortedDSYMs = Array(recommendedDSYMs.union(optionalDSYMs)).sorted {
            $0.targetName.caseInsensitiveCompare($1.targetName) == .orderedAscending
        }
        expectedUUIDs = Set<BinaryUUID>(sortedDSYMs.map { $0.uuid })
    }

    init(combining requirements: [DSYMRequirements]) {
        var recommendedDSYMs = Set<DSYMRequirement>()
        var optionalDSYMs = Set<DSYMRequirement>()

        for requirement in requirements {
            recommendedDSYMs.formUnion(requirement.recommendedDSYMs.values)
            optionalDSYMs.formUnion(requirement.optionalDSYMs.values)
        }

        self.init(recommendedDSYMs: recommendedDSYMs, optionalDSYMs: optionalDSYMs)
    }
}

struct DSYMRequirement: Equatable, Hashable, Sendable {
    let targetName: String
    let uuid: BinaryUUID
}
