//
//  Updates.swift
//  MacSymbolicator
//

import Foundation

struct Version {
    let major: Int
    let minor: Int
    let patch: Int

    init(string: String) {
        let components = string.components(separatedBy: ".")

        major = components.count > 0 ? Int(components[0]) ?? 0 : 0
        minor = components.count > 1 ? Int(components[1]) ?? 0 : 0
        patch = components.count > 2 ? Int(components[2]) ?? 0 : 0
    }

    var string: String {
        "\(major).\(minor).\(patch)"
    }
}

extension Version: Comparable {
    public static func == (lhs: Version, rhs: Version) -> Bool {
        lhs.major == rhs.major &&
        lhs.minor == rhs.minor &&
        lhs.patch == rhs.patch
    }

    public static func < (lhs: Version, rhs: Version) -> Bool {
        lessThan(lhs: lhs.major, rhs: rhs.major, whenEqual: {
            lessThan(lhs: lhs.minor, rhs: rhs.minor, whenEqual: {
                lessThan(lhs: lhs.patch, rhs: rhs.patch, whenEqual: nil)
            })
        })
    }

    private static func lessThan(lhs: Int, rhs: Int, whenEqual: (() -> Bool)?) -> Bool {
        if lhs < rhs {
            return true
        } else if lhs > rhs {
            return false
        } else {
            return whenEqual?() ?? false
        }
    }
}

final class Updates {
    enum UpdatesError: Error {
        case invalidURL
        case network(Int)
        case emptyResponse
        case parsing(Error?)
        case noReleases
        case couldntReadAppVersion
    }

    struct Release: Codable, Comparable {
        static func < (lhs: Updates.Release, rhs: Updates.Release) -> Bool {
            lhs.version < rhs.version
        }

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case url = "html_url"
            case name
            case tagName = "tag_name"
        }

        let url: URL
        let name: String
        let tagName: String

        var version: Version {
            Version(string: tagName)
        }
    }

    static func availableUpdate(
        forUser user: String,
        repository: String,
        callback: @escaping (Release?, UpdatesError?) -> Void
    ) {
        let mainCallback: (Release?, UpdatesError?) -> Void = { release, error in
            DispatchQueue.main.async { callback(release, error) }
        }

        releases(forUser: user, repository: repository) { releases, error in
            guard let highestVersionRelease = releases?.max() else {
                if releases?.isEmpty == true {
                    return mainCallback(nil, UpdatesError.noReleases)
                } else {
                    return mainCallback(nil, error)
                }
            }

            guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                return mainCallback(nil, UpdatesError.couldntReadAppVersion)
            }

            if highestVersionRelease.version > Version(string: appVersion) {
                return mainCallback(highestVersionRelease, nil)
            } else {
                return mainCallback(nil, nil)
            }
        }
    }

    static func releases(
        forUser user: String,
        repository: String,
        callback: @escaping ([Release]?, UpdatesError?) -> Void
    ) {
        let mainCallback: ([Release]?, UpdatesError?) -> Void = { releases, error in
            DispatchQueue.main.async { callback(releases, error) }
        }

        guard let url = URL(string: "https://api.github.com/repos/\(user)/\(repository)/releases") else {
            return mainCallback(nil, UpdatesError.invalidURL)
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if statusCode == 200 {
                if let data = data {
                    let decoder = JSONDecoder()

                    let releases: [Release]

                    do {
                        releases = try decoder.decode([Release].self, from: data)
                    } catch {
                        return mainCallback(nil, UpdatesError.parsing(error))
                    }

                    return mainCallback(releases.sorted(), nil)
                } else {
                    return mainCallback(nil, UpdatesError.emptyResponse)
                }
            } else {
                return mainCallback(nil, UpdatesError.network(statusCode))
            }
        }.resume()
    }
}
