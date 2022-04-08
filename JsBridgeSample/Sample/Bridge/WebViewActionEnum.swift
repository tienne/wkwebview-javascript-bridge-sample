enum WebViewAction {
    case appVersion
    case navigationPop
    
    init?(host: String) {
        switch host {
        
        case "appVersion":
            self = .appVersion
        
        case "pop":
            self = .navigationPop
        
        default: return nil
        }
    }
}
