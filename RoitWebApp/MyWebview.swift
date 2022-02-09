

import SwiftUI
import WebKit
import Combine
import FirebaseFirestore

// uikit 의 uiview 를 사용할수 있도록 한다.
// UIViewControllerRepresentable

struct MyWebview: UIViewRepresentable {
   
    @EnvironmentObject var viewModel : WebViewModel
    @ObservedObject var networkManager = NetworkManager()
    
//    let USER_NUMBER: String
    
    var urlToLoad: String
    let refreshHelper = WebViewRefreshControlHelper()
    //코디네이터 만들기.
    func makeCoordinator() -> MyWebview.Coordinator {
        return MyWebview.Coordinator(self)
    }
    

    // ui view 만들기
    func makeUIView(context: Context) -> WKWebView {
        
        // unwrapping
        guard let url = URL(string: self.urlToLoad) else {
            return WKWebView()
        }
        
        // 웹뷰 인스턴스 생성
        let webview = WKWebView(frame: .zero, configuration: createWKWebConfig())
        webview.uiDelegate = context.coordinator as! WKUIDelegate
        webview.navigationDelegate = context.coordinator as? WKNavigationDelegate
        webview.allowsBackForwardNavigationGestures = true
        
        //리프레시 컨트롤 달아주기
        let myRefreshControl = UIRefreshControl()
        myRefreshControl.tintColor = UIColor.blue
        refreshHelper.viewModel = viewModel
        refreshHelper.refreshControl = myRefreshControl
        
        myRefreshControl.addTarget(refreshHelper,action: #selector(WebViewRefreshControlHelper.didRefresh),for : .valueChanged)
        
        webview.scrollView.refreshControl = myRefreshControl
        webview.scrollView.bounces = true
        
        
        webview.load(URLRequest(url: url))

//        [앱 처리] 오프라인에 있는 html파일을 여는 방식.+ sqlite(기존)
//        [웹 처리] serviceworker를 활용해 캐시에 내장된 웹페이지를 쓰는 방법.
        
//        let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
//        let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
//        webview.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        
        return webview
        
    }
    
    // 업데이트 ui view
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<MyWebview>) {
           
       }

    func createWKWebConfig () -> WKWebViewConfiguration {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.javaScriptEnabled = true
        
        let wkWebConfig  = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self.makeCoordinator(), name: "callbackHandler")
        wkWebConfig.userContentController = userContentController
        wkWebConfig.preferences = preferences
        return wkWebConfig
    }
    
    class Coordinator : NSObject{
        var myWebView : MyWebview// swiftUI view
        var subscriptions = Set<AnyCancellable>()
        init(_ myWebView: MyWebview)
        {
            self.myWebView = myWebView
        }
    }
    
}



extension MyWebview.Coordinator : WKUIDelegate
{
//    @State static var popupWebView:WKWebView = {
//        var popupWebView = WKWebView(frame: .bounds, configuration: configuration)
//        return popupWebView
//    }()
//    @State static var popupWebView: WKWebView?
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        self.myWebView.viewModel.jsAlertEvent.send(JsAlert(message, .JS_ALERT))
        completionHandler()
    }
    
    
    func webView(_ webView: WKWebView,        runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?,    initiatedByFrame frame: WKFrameInfo,   completionHandler: @escaping (String?) -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage")
        self.myWebView.viewModel.jsAlertEvent.send(JsAlert(prompt, .JS_ALERT))
//        completionHandler()
        completionHandler(prompt)
    }
    
    
    
    
    
    struct Holder {
            static var _popupWebView:WKWebView?// = false
        }
    public var popupWebView:WKWebView? {
        get {return Holder._popupWebView}
        set(newValue) {Holder._popupWebView = newValue}
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        let frame = UIScreen.main.bounds
//        var popupWebView: WKWebView?
        popupWebView = WKWebView(frame: frame, configuration: configuration)
//        popupWebView = WKWebView(frame: webView.bounds, configuration: configuration)
        popupWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popupWebView?.navigationDelegate = webView.navigationDelegate
        popupWebView?.uiDelegate = webView.uiDelegate
        webView.addSubview(popupWebView!)
        
        let loadUrl : String = navigationAction.request.url!.absoluteString
        print("url:"+loadUrl)
        
        
        return popupWebView!
//        return nil
//        let loadUrl : String = navigationAction.request.url!.absoluteString
//        if (loadUrl.contains("https://") || loadUrl.contains("http://"))
//        {
//            if let aString = URL(string:(navigationAction.request.url?.absoluteString )!) {
//                UIApplication.shared.open(aString, options:[:], completionHandler: { success in
//                })
//            }
//        } else {
//            print("else"+loadUrl)
//        }
//        return nil


    }
    
}
extension MyWebview.Coordinator : WKNavigationDelegate{
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {print("didStartProvisionalNavigation")
        myWebView.viewModel
            .webNavigationSubject
            .sink
        {
            (action : Web_Nav) in
            print("들어온 네비게이션 액션: \(action)")
                  switch action{
            case .BACK:
                if webView.canGoBack{
                    webView.goBack()}
            case .FORWARD:
                if webView.canGoForward{
                    webView.goForward()}
            case .REFRESH:
                    webView.reload()
                  }            
        }.store(in: &subscriptions)
    }
    func SaveToken_to_KCC(IsDev:Bool, token:String, user: String)
    {
        let url_dev = IsDev ? "http://koupdev.kccworld.net/api/setuserdevice" : "https://koup.kccworld.net/api/setuserdevice"
        let param = "?user=\(user)&type=i&token=\(token)&version=0.2.3&build=20211111&number=&imei=&model=iPhone&carrier=&manufacturer=Apple&sender=APNS"
        let url = URL(string: (url_dev+param))!
                      
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")

        print(request)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
                    }
        task.resume()
    }
    func toFirestore(token:String, user: String,name: String)
    {
        
        let ex_user = UserDefaults.standard.string( forKey: "ex_user" ) ?? "noname"
        if(ex_user.elementsEqual(user))//이미 저장되었으면 저장하지 말 것.
        {return}
        
        print("saveFirestore \(user) \(name) \(token)")
        let db = Firestore.firestore()
        db.collection("users").document(user).setData([
            "UserName": name,
            "FCMToken": token
        ])
        { err in
            if let err = err { print("Error writing document: \(err)")}
            else { print("Document successfully written!")}
        }
        
        
        
        if(!ex_user.elementsEqual("noname"))
        {
            db.collection("users").document(ex_user).delete() { err in
                if let err = err {print("Error removing document: \(err)")}
                else {print("Document successfully removed!")}
            }
        }
        UserDefaults.standard.set( user, forKey: "ex_user" )
        
        
        
    }
    func makeStringKoreanEncoded(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        
//        print("webView didfinish"+title)

//        print("didfinish"+delegate.push_url)
        
        
//        print("window.location.href")
        
        webView.evaluateJavaScript("window.location.href") { (response, error) in
            
            
            print(error)
            
            if let title = response as? String {
                
                print(response)
                print(title)
                if(self.myWebView.viewModel.LoginCookie_Checked)//로그인 후 1회만 작동.
                {
                    print("로그인체크전:"+title)
                    //로그인전, 로그아웃 화면(:index경로)에서 초기화한다.
                    if(title == "http://roit.smartpmis.net/" || title=="https://roit.smartpmis.net/")
                    {
                        print("로그인체크")
                        self.myWebView.viewModel.LoginCookie_Checked=false }
                }
                else if(title.contains("http://roit.smartpmis.net/main")){//} || title=="https://roit.smartpmis.net/main/1149"){
                    
                    let dataStore = WKWebsiteDataStore.default()
                    dataStore.httpCookieStore.getAllCookies({
                        (cookies) in
                        var u_id:String=""
                        var u_name:String=""
                        for cookie in cookies
                        {
                            if(cookie.name=="UserID")
                            {
                                u_id = cookie.value
                            }
                            if(cookie.name=="UserName")
                            {
                                u_name = cookie.value.removingPercentEncoding(using: .eucKrDecode)!
                            }
                        }
//                        print("id:\(u_id)")
//                        print("name:\(u_name)")
//                        return
//                        let delegate = UIApplication.shared.delegate as! AppDelegate //등록된 토큰.
                        let delegate = UIApplication.shared.delegate as! AppDelegate
//                        self.toFirestore(token:"-", user:ex_id,name:u_name)
                        self.toFirestore(token:delegate.token, user:u_id,name:u_name)
                        
                        self.myWebView.viewModel.LoginCookie_Checked=true
                    })
                    
                    
                    
                }}
        }
    }
    

    // 네비게이션 액션 들어올때
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // 리퀘스트 url 이 없으면 리턴
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        switch url.scheme {
        case "tel", "mailto": // 전화번호, 이메일
            // 외부로 열기
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
            
        }
    }
    
    //응답들어올때
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        print("webView - decidePolicyFor navigationResponse")
        
        // 클릭된 url, 파일형태, 파일 이름
        guard let url = navigationResponse.response.url,
              var mimeType = navigationResponse.response.mimeType,
              let filename = navigationResponse.response.suggestedFilename else {
            decisionHandler(.cancel)
            return
        }
        
        print("webView 다운로드 테스트 - url: \(url)")
        print("webView 다운로드 테스트 - mimeType: \(mimeType)")
        print("webView 다운로드 테스트 - filename: \(filename)")
            
            //                          -----                          //
//            var title = "\(url)"
//            var u_id:String=""
//            var u_name:String=""
//            if(self.myWebView.viewModel.LoginCookie_Checked)//로그인 후 1회만 작동.
//            {
//                print("로그인체크전:"+title)
//                //로그인전, 로그아웃 화면(:index경로)에서 초기화한다.
//                if(title == "http://roit.smartpmis.net/" || title=="https://roit.smartpmis.net/")
//                {
//                    print("로그인체크")
//                    self.myWebView.viewModel.LoginCookie_Checked=false }
//            }
//                else if(title.contains("http://roit.smartpmis.net/main")){//} || title=="https://roit.smartpmis.net/main/1149"){
//                    //쿠키생성된 후 (:Intro 페이지)에서 KCC 서버로 토큰을 전송한다.
//                    print("캐시가져옴")
//                    let dataStore = WKWebsiteDataStore.default()
//                    dataStore.httpCookieStore.getAllCookies({ (cookies) in
//                        for cookie in cookies
//                        {
//                            print(cookie)
////                            UserName
////                            if(cookie.name=="UserID")
////                            { u_id = cookie.value}
////                            else if(cookie.name=="UserName")
////                            {u_name = cookie.value}
////                            print(cookie)
//
//                        }})
////                    print("캐시가져옴"+u_id+"  "+u_name)
//                    return;
//                    let delegate = UIApplication.shared.delegate as! AppDelegate //등록된 토큰.
//                    self.toFirestore(token:delegate.token, user:u_id,name:u_name)
//                    self.myWebView.viewModel.LoginCookie_Checked=true
//
//
//                }
            
            
            
        //                          -----                          //
        // 사이트 일때
        if mimeType == "text/html" {
            decisionHandler(.allow)
        } else {//다운로드 일 때.
            self.popupWebView?.removeFromSuperview()
            downloadFile(webView: webView, url: url, fileName: filename, completion: { fileUrl in
                print("다운로드 받은 fileUrl: ", fileUrl)
                DispatchQueue.main.async {
                    if let fileUrl = fileUrl {
                        // 다운로드가 완료 되었다고 알린다
                        self.myWebView.viewModel.downloadEvent.send(fileUrl)
                    } else {
//                        self.myWebView.viewModel.jsAlertEvent.send(JsAlert(filename, .DOWNLOAD_FAILED))
                    }
                }
            })
            
            decisionHandler(.cancel)
        }
    }
}

extension MyWebview.Coordinator : WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKWebViewCoordinator - userContentController / message: \(message)")
        
        if message.name == "callbackHandler" {
            print("JSON 데이터가 웹으로부터 옴: \(message.body)")
            if let receivedData : [String: String] = message.body as? Dictionary {
                print("receivedData: \(receivedData)")
                myWebView.viewModel.jsAlertEvent.send(JsAlert(receivedData["message"], .JS_BRIDGE))
            }
        }
        
    }
}
extension String {
    func bytesByRemovingPercentEncoding(using encoding: String.Encoding) -> Data {
            struct My {
                static let regex = try! NSRegularExpression(pattern: "(%[0-9A-F]{2})|(.)", options: .caseInsensitive)
            }
            var bytes = Data()
            let nsSelf = self as NSString
            for match in My.regex.matches(in: self, range: NSRange(0..<self.utf16.count)) {
                if match.range(at: 1).location != NSNotFound {
                    let hexString = nsSelf.substring(with: NSMakeRange(match.range(at: 1).location+1, 2))
                    bytes.append(UInt8(hexString, radix: 16)!)
                } else {
                    let singleChar = nsSelf.substring(with: match.range(at: 2))
                    bytes.append(singleChar.data(using: encoding) ?? "?".data(using: .ascii)!)
                }
            }
            return bytes
        }
    func removingPercentEncoding(using encoding: String.Encoding) -> String? {
        return String(data: bytesByRemovingPercentEncoding(using: encoding), encoding: encoding)
    }

}

extension String.Encoding {
    static let eucKrDecode = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(0x0422))
}
//다운로드 관련.
extension MyWebview.Coordinator {
    
    fileprivate func downloadFile(webView: WKWebView,
                                  url: URL,
                                  fileName: String,
                                  completion: @escaping (URL?) -> Void ){
        print("downloadFile() called")
        
        // 웹뷰 쿠키 가져오기
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({ fetchedCookies in
            
            // urlSession
            let session = URLSession.shared
            // 가져온 쿠키로 urlSession 설정
            session.configuration.httpCookieStorage?.setCookies(fetchedCookies, for: url, mainDocumentURL: nil)
          
            // 다운로드 진행
            let downloadTask = session.downloadTask(with: url) { localUrl, urlResponse, error in
                print("다운로드 완료")

                // 다운로드 완료시
                if let localUrl = localUrl {
                    let finalDestinationUrl = self.moveDownloadedFile(url: localUrl, fileName: fileName)
                    completion(finalDestinationUrl)
                } else { // 다운로드 실패시
                    completion(nil)
//
                }
                
                
            }
            downloadTask.resume()
            
        })
        
    }
    fileprivate func moveDownloadedFile(url: URL, fileName: String) -> URL {
        // 임시 경로
//        print("이동.")
        let tempDir = NSTemporaryDirectory()
        let destinationPath = tempDir + fileName
        let destinationFileURL = URL(fileURLWithPath: destinationPath)
        // 같은 경로에 아이템이 있으면 지워라
        try? FileManager.default.removeItem(at: destinationFileURL)
        // 해당 경로로 다운받은 아이템을 이동시켜라
        try? FileManager.default.moveItem(at: url, to: destinationFileURL)
        
        print("이동.",destinationFileURL)
        return destinationFileURL
    }
}
//struct MyWebview_Previews: PreviewProvider {
//    static var previews: some View {
//        MyWebview(urlToLoad: "https://www.naver.com")
//    }
//}
//
//
