//
//  RJSensorModel.swift
//  swiftTest
//
//  Created by RJ on 2018/7/16.
//  Copyright © 2018年 RJ. All rights reserved.
//

import UIKit
import CoreBluetooth
enum OemType : String {
    
    case F0               = "F0"
    
}
class RJSensorModel: NSObject {
    var cbPeripheral          : CBPeripheral?
    var name                  : String?
    var RSSI                  : NSInteger = 0
    var MacAdress             : String?
    var oemData               : String?
    var oemType               : OemType?
    var version               : String?
    var advertisementData     : [String : Any]?
    override init() {
        super.init()
    }
    convenience init(_ sensor:CBPeripheral, _ advertisement:[String : Any], _ rssi:NSNumber) {
        self.init()
        cbPeripheral      = sensor
        name              = sensor.name
        RSSI              = NSInteger(fabs(rssi.doubleValue))
        advertisementData = advertisement
        
        let manuFactureData = advertisement[CBAdvertisementDataManufacturerDataKey] as! Data
        guard let manuFactureSting = String(data: manuFactureData.prefix(6), encoding: .utf8) else { return  }
        
        oemType             = OemType(rawValue: String(manuFactureSting.prefix(2)))
        oemData             = String(manuFactureSting.suffix(4))
    }
    convenience init(_ infoDic:[String:Any]?) {
        self.init()
        guard let info = infoDic else { return  }
        cbPeripheral        = info["cbPeripheral"] as? CBPeripheral
        name                = info["name"] as? String
        MacAdress           = info["MacAdress"] as? String
        RSSI                = info["RSSI"] as! NSInteger
        oemData             = info["oemData"] as? String
        oemType             = info["oemType"] as? OemType
        version             = info["version"] as? String
        advertisementData   = info["advertisementData"] as? [String:Any]
    }
    func infoDic() -> [String:Any] {
        var infoDic = [String:Any]()
        infoDic["cbPeripheral"]      = cbPeripheral
        infoDic["name"]              = name
        infoDic["RSSI"]              = RSSI
        infoDic["MacAdress"]         = MacAdress
        infoDic["oemData"]           = oemData
        infoDic["oemType"]           = oemType
        infoDic["version"]           = version
        infoDic["advertisementData"] = advertisementData
        
        return infoDic
    }
    func correctOrderOemType() -> String {
        let string = oemType?.rawValue
        return  String(string!.suffix(1) + string!.prefix(1))
    }
}
