import Foundation

struct CLIDDCBridge {
    private let m1ddcPath = "/opt/homebrew/bin/m1ddc"

    func setBrightness(_ value: Int) -> Result<Void, DDCBridgeError> {
        runCommand(["set", "luminance", String(value)])
    }

    func setContrast(_ value: Int) -> Result<Void, DDCBridgeError> {
        runCommand(["set", "contrast", String(value)])
    }

    private func runCommand(_ arguments: [String]) -> Result<Void, DDCBridgeError> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: m1ddcPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failure(.processLaunchFailed(error.localizedDescription))
        }

        guard process.terminationStatus == 0 else {
            let output = String(
                data: pipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            return .failure(.commandFailed(status: process.terminationStatus, output: output))
        }

        return .success(())
    }
}

enum DDCBridgeError: LocalizedError {
    case processLaunchFailed(String)
    case commandFailed(status: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .processLaunchFailed(let reason):
            return "Failed to launch m1ddc: \(reason)"
        case .commandFailed(let status, let output):
            return "m1ddc exited with \(status): \(output)"
        }
    }
}
