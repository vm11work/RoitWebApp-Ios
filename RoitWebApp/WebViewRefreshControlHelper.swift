import Foundation
import UIKit

class WebViewRefreshControlHelper{
    
    var refreshControl : UIRefreshControl?
    var viewModel : WebViewModel?
    
    @objc func didRefresh(){
        print("WebViewRefreshControlHelper - didRefresh() called")
        guard let refreshControl = refreshControl,
        let viewModel = viewModel else {
            print ("refreshControl, viewModel이 없다.")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.8, execute:{
            print("리프레시 액션이 들어왔다.")
            //리프레시 하라고 알려주기.
            viewModel.webNavigationSubject.send(.REFRESH)
            refreshControl.endRefreshing()
        })
    }
}
