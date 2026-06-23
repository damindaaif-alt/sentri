import Foundation
import CallKit

// Reads the blocked-number list from the shared App Group UserDefaults suite
// and populates the system call directory. Flutter writes to the suite via
// the `syncBlocklist` MethodChannel call in AppDelegate.
class CallDirectoryHandler: CXCallDirectoryProvider {

  private static let appGroupID = "group.com.sentri.app"
  private static let blockedKey  = "sentri_blocked_numbers"
  private static let callerIdKey = "sentri_caller_ids"

  override func beginRequest(with context: CXCallDirectoryExtensionContext) {
    context.delegate = self

    let suite = UserDefaults(suiteName: Self.appGroupID)

    // Blocked numbers — system silences these calls
    let blocked = suite?.stringArray(forKey: Self.blockedKey) ?? []
    let sortedBlocked = blocked
      .compactMap { CXCallDirectoryPhoneNumber($0) }
      .sorted()
    for number in sortedBlocked {
      context.addBlockingEntry(withNextSequentialPhoneNumber: number)
    }

    // Caller ID labels — system shows these in the incoming-call screen
    let callerIds = (suite?.array(forKey: Self.callerIdKey) as? [[String: Any]]) ?? []
    let sortedCallerIds = callerIds
      .compactMap { entry -> (CXCallDirectoryPhoneNumber, String)? in
        guard let raw = entry["number"] as? String,
              let num = CXCallDirectoryPhoneNumber(raw),
              let label = entry["label"] as? String else { return nil }
        return (num, label)
      }
      .sorted { $0.0 < $1.0 }
    for (number, label) in sortedCallerIds {
      context.addIdentificationEntry(withNextSequentialPhoneNumber: number, label: label)
    }

    context.completeRequest()
  }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
  func requestFailed(for extensionContext: CXCallDirectoryExtensionContext,
                     withError error: Error) {
    // Extension context errors are shown in the Settings > Phone > Call Blocking UI.
  }
}
