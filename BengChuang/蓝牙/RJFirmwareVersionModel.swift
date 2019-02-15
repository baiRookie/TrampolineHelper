//
//  RJFirmwareVersionModel.swift
//  CTMediator
//
//  Created by RJ on 2018/9/11.
//

import UIKit

class RJFirmwareVersionModel: NSObject {
    var ForceUpdate     : Int?
    var Path            : String?
    var Remark          : String?
    var Version         : String?
    var VersionDateTime : String?
    init(_ versionInfo:[String:Any]?) {
        guard let info = versionInfo else { return  }
        ForceUpdate     = info["ForceUpdate"] as? Int
        Path            = info["Path"] as? String
        Remark          = info["Remark"] as? String
        Version         = info["Version"] as? String
        VersionDateTime = info["VersionDateTime"] as? String
    }
}
