//
//  WebLoginViewController.swift
//  Electsys Utility
//
//  Created by 法好 on 2020/12/8.
//  Copyright © 2020 yuxiqian. All rights reserved.
//

import Alamofire
import Cocoa
import WebKit

class WebLoginViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        embedWebView.uiDelegate = self
        embedWebView.navigationDelegate = self

        startLoading()
    }

    @IBOutlet var embedWebView: WKWebView!
    @IBOutlet var backwardsButton: NSButton!
    @IBOutlet var forwardButton: NSButton!
    @IBOutlet var urlLabel: NSTextField!

    var delegate: WebLoginDelegate?

    @IBAction func onRefresh(_ sender: NSButton) {
        startLoading()
    }

    @IBAction func goBack(_ sender: NSButton) {
        embedWebView.goBack()
    }

    @IBAction func goForward(_ sender: NSButton) {
        embedWebView.goForward()
    }

    @IBAction func giveUpLogin(_ sender: NSButton) {
        done(success: false)
    }

    @IBAction func completeLogin(_ sender: NSButton) {
        done(success: true)
    }

    func startLoading() {
        let request = URLRequest(url: URL(string: LoginConst.initUrl)!)
        embedWebView.load(request)
        refreshUI()
    }

    func refreshUI() {
        backwardsButton.isEnabled = embedWebView.canGoBack
        forwardButton.isEnabled = embedWebView.canGoForward
        urlLabel.stringValue = embedWebView.url?.absoluteString ?? "空"

        ESLog.info("redirected to %@", embedWebView.url?.absoluteString ?? "<< error page >>")

        if embedWebView.url?.absoluteString.starts(with: LoginConst.mainPageUrl) ?? false {
            done()
        }
    }

    func done(success: Bool = true) {
        if success {
            if #available(OSX 10.13, *) {
                embedWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                    for cookie in cookies {
                        ESLog.info("get cookie at domain `%@`, pair: %@: %@", cookie.domain, cookie.name, cookie.value)
                        Alamofire.HTTPCookieStorage.shared.setCookie(cookie)
                    }
                    self.delegate?.callbackWeb(success)
                }
            }
        } else {
            delegate?.callbackWeb(success)
        }
    }

    // MARK: - WKWebView Delegate Stuff

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshUI()
    }
}
