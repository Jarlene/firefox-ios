/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct BlurTableViewAction {

    public private(set) var handler: (BlurTableViewAction -> Void)
    public private(set) var title: String
    public private(set) var iconString: String


    public init(title: String, iconString: String, handler: (BlurTableViewAction -> Void)) {
        self.handler = handler
        self.title = title
        self.iconString = iconString
    }
}
