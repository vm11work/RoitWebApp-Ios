import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var myWebVM :WebViewModel
    @ObservedObject var networkManager = NetworkManager()

    @State var jsAlert : JsAlert?
    @State var webTitle : String = ""
    @State var textString = ""
    @State var shouldShowAlert = false
    
#if DEBUG
//    @State var url : String = "http://koupdev.kccworld.net"
//        @State var url : String = "https://vm11work.github.io/cache-test/microphone-test"
    @State var url : String = "http://roit.smartpmis.net/"
    @State var welcometitle : String = "로이 - s    martpmis"
#else
    //@State var url : String = "https://vm11work.github.io/cache-test"
//    @State var url : String = "https://gymcoding.github.io/vuetify-admin-template/#"
//    @State var url : String = "https://www.naver.com"
        @State var url : String = "http://roit.smartpmis.net"
//    @State var url : String = "https://vm11work.github.io/webtest/cookiemaker.html"
//            @State var url : String = "https://tuentuenna.github.io/simple_js_alert/"
//    @State var url : String = "https://vm11work.github.io/cache-test/download.html"
//    @State var url : String = "https://vm11work.github.io/fastvue"
//    @State var url : String = "https://koup.kccworld.net"
    
    @State var welcometitle : String = "운영"
#endif
    var body: some View {
        
        ZStack{
            Color(red: 57 / 255, green: 75 / 255, blue: 112 / 255).edgesIgnoringSafeArea(.all)            
            VStack{ //위에서 아래로 UI 배치
                MyWebview(urlToLoad: url) //웹뷰
                if !networkManager.isConnected {//오프라인 일때. 재접속 버튼.
                    Button {
                        print("Handle action..")
                    } label: {
                        Text("재접속")
                            .padding()
                            .font(.headline)
                            .foregroundColor(Color(.systemBlue))
                    }
                    .frame(width: 140)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .padding()
                }
                let delegate = UIApplication.shared.delegate as! AppDelegate
                
                #if DEBUG //디버그 모드일때만, 개발용 표시하기.
                    Text(delegate.push_url)
                    .font(.largeTitle)
                    .onAppear {}
                #endif
                
            }
            .alert(item: $jsAlert, content: { alert in
                createAlert(alert)
            })
        }// ZStack
        
        .onReceive(myWebVM.jsAlertEvent, perform: { jsAlert in //javascript alert창 이벤트 발생처리.
            print("ContentView - jsAlert: ", jsAlert)
            self.jsAlert = jsAlert
        })
        
        .onReceive(myWebVM.webSiteTitleSubject, perform: { receivedWebTitle in
            print("ContentView - receivedWebTitle: ", receivedWebTitle)
            self.webTitle = receivedWebTitle
        })
        .onReceive(myWebVM.downloadEvent, perform: { fileUrl in
            print("ContentView - fileUrl: ", fileUrl)
            // 다운로드된 파일을 공유한다.
            shareSheet(url: fileUrl)
        })
        // 웹사이트 타이틀 변경 이벤트 처리.
        // koup의 경우 /intro 화면이 로드 때
        // 세션에 유저id가 저장되고,
        // 이 유저id, FCM토큰 값을 붙여서 kcc서버에 get방식으로 저장한다.
        
    }
}
extension ContentView {
    
    func shareSheet(url: URL) {
        print("ContentView - shareSheet() called")
        let uiActivityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {//아이패드 에러방지.
            
            print("아이패드 shared 호출")// -> 바로 다운로드로 고치기.
            uiActivityVC.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
            uiActivityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 300, height: 350)
            uiActivityVC.popoverPresentationController?.permittedArrowDirections = [.left]
        }

        
        UIApplication.shared.windows.first?.rootViewController?.present(uiActivityVC, animated: true, completion: nil)
    }
    
    func createAlert(_ alert: JsAlert) -> Alert {
//        Alert(title: Text(alert.type.description),
        Alert(title: Text(alert.message),
              message: Text(""),
              dismissButton: .default(Text("확인"), action: {
                print("알림창 확인 버튼이 클릭되었다.")
              }))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
