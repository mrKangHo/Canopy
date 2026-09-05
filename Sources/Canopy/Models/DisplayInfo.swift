import AppKit

struct DisplayInfo: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
}

/// What a video selection applies to — every connected display at once, or
/// just one of them.
enum DisplaySelection: Hashable {
    case all
    case display(CGDirectDisplayID)
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
