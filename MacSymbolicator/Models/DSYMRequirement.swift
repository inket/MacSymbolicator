//
//  DSYMRequirement.swift
//  MacSymbolicator
//

import Foundation

struct DSYMRequirements: Equatable, Hashable, Sendable {
    let recommendedDSYMs: [BinaryUUID: DSYMRequirement]
    let optionalDSYMs: [BinaryUUID: DSYMRequirement]
    let systemDSYMs: [BinaryUUID: DSYMRequirement]

    let sortedDSYMs: [DSYMRequirement]
    let expectedUUIDs: Set<BinaryUUID>
    let expectedNonSystemUUIDs: Set<BinaryUUID>

    init(
        recommendedDSYMs: Set<DSYMRequirement>,
        optionalDSYMs: Set<DSYMRequirement>,
        systemDSYMs: Set<DSYMRequirement>
    ) {
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

        var mappedSystemDSYMs: [BinaryUUID: DSYMRequirement] = [:]
        for dsym in systemDSYMs {
            mappedSystemDSYMs[dsym.uuid] = dsym
        }
        self.systemDSYMs = mappedSystemDSYMs

        let nonSystemDSYMs = recommendedDSYMs.union(optionalDSYMs)
        let allDSYMs = nonSystemDSYMs.union(systemDSYMs)
        sortedDSYMs = allDSYMs.sorted {
            $0.targetName.caseInsensitiveCompare($1.targetName) == .orderedAscending
        }
        expectedUUIDs = Set<BinaryUUID>(sortedDSYMs.map { $0.uuid })
        expectedNonSystemUUIDs = Set<BinaryUUID>(nonSystemDSYMs.map { $0.uuid })
    }

    init(combining requirements: [DSYMRequirements]) {
        var recommendedDSYMs = Set<DSYMRequirement>()
        var optionalDSYMs = Set<DSYMRequirement>()
        var systemDSYMs = Set<DSYMRequirement>()

        for requirement in requirements {
            recommendedDSYMs.formUnion(requirement.recommendedDSYMs.values)
            optionalDSYMs.formUnion(requirement.optionalDSYMs.values)
            systemDSYMs.formUnion(requirement.systemDSYMs.values)
        }

        self.init(
            recommendedDSYMs: recommendedDSYMs,
            optionalDSYMs: optionalDSYMs,
            systemDSYMs: systemDSYMs
        )
    }
}

struct DSYMRequirement: Equatable, Hashable, Sendable {
    let targetName: String
    let uuid: BinaryUUID
}
