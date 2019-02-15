//
//  da.swift
//  XiaoYu_Bluetooth_Example
//
//  Created by RJ on 2018/8/30.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import CoreBluetooth
import CTMediator

let targaetName = "BC_BluetoothHelper"
var defaultParams :[AnyHashable :Any] = ["defaultKey":"defaultValue",
                                         kCTMediatorParamsKeySwiftTargetModuleName:"RJBluetooth"]
private enum ActionName:String {
    case ScanSensor
    case StopScan
    case Connect
    case DisConnect
    
    case RequestBatteryEnergy
    case RequestVersion
    case CheckPreparationForUpdateFirmware
    case UpdateFirmware
    
    case EnterRealTimeMode
    case ExitRealTimeModel
    
    case ReadMacAddress
    case ReStored
    case SensorCorrect
}

//MARK: - 连接外设
extension CTMediator {
    /// 搜索外设
    ///
    /// - Parameters:
    ///   - services: 服务
    ///   - options: 可选字典，指定用于自定义扫描的选项 是否重复扫描已发现的设备 默认为NO
    ///              CBCentralManagerScanOptionAllowDuplicatesKey:false
    class func scanSensor(withServices services :[CBUUID]?, options:[String : Any]? , handler:ScanSensorResultHandler_XiaoYu?)  {
        if services != nil {
            defaultParams["services"] = services!
        }
        if options != nil {
            defaultParams["options"]  = options!
        }
        if handler != nil {
            defaultParams["handler"]  = handler!
        }
        performAction(.ScanSensor)
    }
    /// 结束搜索外设
    class func stopScan()  {
        performAction(.StopScan)
    }
    
    /// 连接外设
    ///
    /// - Parameters:
    ///   - sensor: 外设模型
    ///   - options: 可选字典，指定用于连接状态的提示的选项
    class func connect(_ peripheral: CBPeripheral?, _ options:[String : Any]? , connnectHandler:ConnectSensorResultHandler_XiaoYu?,_ disConnectHandler:DisConnectSensorResultHandler_XiaoYu? ) -> Void {
        defaultParams["options"]    = options
        defaultParams["connectHandler"]    = connnectHandler
        defaultParams["disConnectHandler"]    = disConnectHandler
        defaultParams["peripheral"] = peripheral
        performAction(.Connect)
    }
    
    /// 断开与外设的连接
    class func disConnect() -> Void {
        performAction(.DisConnect)
    }
}

extension CTMediator {


    /// 进入实时模式
    ///
    /// - Parameter handler: 回调
    class func enterRealTimeMode(state:EnterRealTimeModelStateHandler? , _ handler:EnterRealTimeModelDataHandler?) -> Void {
        defaultParams["state"]  = state
        defaultParams["handler"]  = handler
        performAction(.EnterRealTimeMode)
    }
    
    /// 退出实时模式
    class func exitRealTimeModel() -> Void {
        performAction(.ExitRealTimeModel)
    }


    /// 请求电池电量
    ///
    /// - Parameter handler: 回调
    class func requestBatteryEnergy(_ handler:requestBattryEnergyHandler?) -> Void {
        defaultParams["handler"]  = handler
        performAction(.RequestBatteryEnergy)
    }
    /// 检查固件升级准备工作
    ///
    /// - Parameter handler: 回调
    class func checkPreparationForUpdateFirmware(_ handler:CheckPreparationForUpdateFirmwareHandler?) -> Void {
        defaultParams["handler"]  = handler
        performAction(.CheckPreparationForUpdateFirmware)
    }
    /// 固件升级
    ///
    /// - Parameter handler: 回调
    class func updateFirmware(_ progressHandler:UpdateFirmwareProgressHandler? , _ handler:ReturnTheSameCommandHanler?) -> Void {
        defaultParams["progressHandler"]  = progressHandler
        defaultParams["handler"]  = handler
        performAction(.UpdateFirmware)
    }
    /// 请求版本号
    ///
    /// - Parameter handler: 回调
    class func requestVersion(_ handler:RequestVersionHandler?) -> Void {
        defaultParams["handler"]  = handler
        performAction(.RequestVersion)
    }
   
    
    /// 读取MAC地址
    ///
    /// - Parameter handler: 回调
    class func readMacAddress(_ handler:ReadMacAddressHandler?) -> Void {
        defaultParams["handler"]  = handler
        performAction(.ReadMacAddress)
    }
    
    
    /// 还原出厂设置
    ///
    /// - Parameter handler: 回调
    class func reStored(_ handler:ReturnTheSameCommandHanler?) -> Void {
        defaultParams["handler"]  = handler
        performAction(.ReStored)
    }
    
    /// 传感器校准
    ///
    /// - Parameter handler: 回调
    class func sensorCorrect(_ handler:SensorCorrectHandeler?) -> Void {
        defaultParams["handler"]  = handler
        performAction(.SensorCorrect)
    }
    
    /// 选择方法执行
    ///
    /// - Parameter action: 方法类型
    private class func performAction(_ action:ActionName) -> Void {
        CTMediator.sharedInstance().performTarget(targaetName, action: action.rawValue, params: defaultParams, shouldCacheTarget: true)
    }
    
    
}

