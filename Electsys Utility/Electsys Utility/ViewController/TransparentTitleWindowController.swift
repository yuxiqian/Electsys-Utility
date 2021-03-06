//
//  TransparentTitleWindowController.swift
//  Electsys Utility
//
//  Created by yuxiqian on 2018/10/14.
//  Copyright © 2018年 yuxiqian. All rights reserved.
//

import Cocoa

class TransparentTitleWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        guard let viewController = contentViewController as? MainViewController else {
            ESLog.error("invalid MainViewController instance")
            return nil
        }
        return viewController.makeTouchBar()
    }
}
