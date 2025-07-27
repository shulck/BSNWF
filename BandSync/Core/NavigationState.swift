import Foundation

class NavigationState: ObservableObject {
    static let shared = NavigationState()
    
    var lastSelectedTab = -1
    
    private init() {}
}
