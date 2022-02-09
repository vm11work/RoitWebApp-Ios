import Foundation
import Combine

typealias Web_Nav = WebViewModel.NAVIGATION

class WebViewModel : ObservableObject{
    var push_url = "intial_url"
    var LoginCookie_Checked=false;
    enum NAVIGATION {
        case BACK,FORWARD,REFRESH
    }
    
    var webNavigationSubject = PassthroughSubject<Web_Nav,Never>()
    var jsAlertEvent = PassthroughSubject<JsAlert, Never>()
    var webSiteTitleSubject = PassthroughSubject<String, Never>()
    
    var downloadEvent = PassthroughSubject<URL, Never>()
}



