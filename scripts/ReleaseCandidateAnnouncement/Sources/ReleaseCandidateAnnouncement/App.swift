import ArgumentParser
import Foundation
import SharedReleaseScript

@main
struct App: AsyncParsableCommand {
    @Option(help: "Authorization token for the Transifex. Example: 'Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var transifexAuthorization: String

    @Option(help: "Authorization token for the Slack. Example: '0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var slackAuthorization: String

    @Option(help: "Authorization token for the Jira. Example: '0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var jiraAuthorization: String

    @Option(help: "Base URL for Jira")
    var jiraBaseURLString: String

    @Option(help: "projects separated by comma. Example: IOS:1,Android:2,WEB:3")
    var jiraProjects: String

    @Option(help: "Next release version. Example: 16.10 if the current version is 16.9")
    var nextReleaseVersion: String?

    @Option(help: "Slack Channel Id's to which the release candidate message should be sent. Separated by comma.")
    var releaseCandidateSlackChannelIds: String

    @Option(help: "Slack Channel Id's to which the code freeze message should be sent. Separated by comma.")
    var codeFreezeSlackChannelIds: String

    @Option(help: "Resource ID to fetch the release notes from the transifex")
    var releaseNotesResourceID: String

    @Option(help: "TestFlight URL for the Mega app, excluding the build number")
    var testflightBaseUrl: String

    func run() async throws {
        guard let jiraBaseURL = URL(string: jiraBaseURLString) else {
            throw AppError.invalidURL("Could not convert \(jiraBaseURLString) to URL")
        }

        print("Fetching the current iOS app version.")
        let versionFetcher = VersionFetcher()
        let currentReleaseVersion = try versionFetcher.fetchVersion()
        print("Current version: \(currentReleaseVersion)")
        
        print("Calculating the next version.")
        let nextReleaseVersion: String
        if let userProvidedVersion = self.nextReleaseVersion,
           userProvidedVersion.components(separatedBy: ".").count >= 2 {
            nextReleaseVersion = userProvidedVersion
        } else {
            nextReleaseVersion = try versionFetcher.nextVersion(from: currentReleaseVersion)
        }
        print("Next version: \(nextReleaseVersion)")

        print("Creating release version iOS \(nextReleaseVersion) for all Main Application Jira projects")
        try await createReleaseVersion(
            version: nextReleaseVersion,
            jiraBaseURL: jiraBaseURL,
            jiraToken: jiraAuthorization,
            jiraProjects: jiraProjects
        )

        print("Fetching the SDK and Chat branch names")
        let sdkVersion = try branchNameForSubmodule(with: Submodule.sdk.path)
        let chatSDKVersion = try branchNameForSubmodule(with: Submodule.chatSDK.path)
        print("SDK: \(sdkVersion) \t Chat SDK: \(chatSDKVersion)")

        print("Fetching release notes for \(currentReleaseVersion)")
        let releaseNotes = try await fetchReleaseNotes(
            for: currentReleaseVersion,
            resourceID: releaseNotesResourceID,
            token: transifexAuthorization
        )
        print("release notes: \(releaseNotes)")

        print("Fetching latest build number for \(currentReleaseVersion)")
        let buildNumber = try versionFetcher.fetchLatestBuildNumber(for: currentReleaseVersion)
        print("Result: \(currentReleaseVersion)(\(buildNumber))")

        print("Sending release candidate message to Slack")
        try await SlackMessageSender
            .sendReleaseCandidateMessage(
                releaseCandidateSlackChannelIds: releaseCandidateSlackChannelIds.components(separatedBy: ","),
                version: currentReleaseVersion,
                buildNumber: buildNumber,
                sdkBranch: sdkVersion,
                chatSDKBranch: chatSDKVersion,
                jiraBaseURLString: jiraBaseURLString,
                releaseNotes: releaseNotes,
                token: slackAuthorization,
                testflightBaseUrl: testflightBaseUrl
            )

        print("Sending code freeze reminder message to Slack")
        try await SlackMessageSender
            .sendCodeFreezeReminderMessage(
                codeFreezeSlackChannelIds: codeFreezeSlackChannelIds.components(separatedBy: ","),
                version: currentReleaseVersion,
                nextVersion: nextReleaseVersion,
                token: slackAuthorization
            )

        print("Finished successfully")
    }
}
