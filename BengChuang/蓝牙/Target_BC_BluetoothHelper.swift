//
//  Target_XiaoYu_Bluetooth.swift
//  CTMediator
//
//  Created by RJ on 2018/8/30.
//

import UIKit


@objc class Target_BC_BluetoothHelper: NSObject {
    var bluetoothHelper = RJBluetoothHelper.shareInstance
    /// 搜索外设
    ///
    /// - Parameters:
    ///   - services: 服务 [String]?
    ///   - options: 可选字典， [String : Any]? 指定用于自定义扫描的选项 是否重复扫描已发现的设备 默认为NO
    ///              CBCentralManagerScanOptionAllowDuplicatesKey:false
    @objc func Action_ScanSensor(_ params:[AnyHashable:Any]) {
        let services = params["services"] as? [CBUUID]
        let options  = params["options"]  as? [String : Any]
        let handler  = params["handler"]  as? ScanSensorResultHandler_XiaoYu
        bluetoothHelper.scanSensor(withServices: services, options: options, handler: handler)
    }
    /// 搜索外设
    ///
    /// - Parameters:
    ///   - services: 服务 [String]?
    ///   - options: 可选字典， [String : Any]? 指定用于自定义扫描的选项 是否重复扫描已发现的设备 默认为NO
    ///              CBCentralManagerScanOptionAllowDuplicatesKey:false
    @objc func Action_ScanSensorWithOriginData(_ params:[AnyHashable:Any]) {
        let services = params["services"] as? [CBUUID]
        let options  = params["options"]  as? [String : Any]
        let handler  = params["handler"]  as? ScanSensorResultHandler
        bluetoothHelper.scanSensorWithOriginData(withServices: services, options: options, handler: handler)
    }
    /// 结束搜索外设
    @objc func Action_StopScan(_ params:[AnyHashable:Any])  {
        bluetoothHelper.stopScan()
    }
    /// 连接外设
    ///
    /// - Parameters:
    ///   - sensor: 外设模型
    ///   - options: 可选字典，指定用于连接状态的提示的选项
    @objc func Action_Connect(_ params:[AnyHashable:Any]) -> Void {
        let peripheral = params["peripheral"] as! CBPeripheral
        let options    = params["options"]   as? [String : Any]
        let connectHandler    = params["connectHandler"]   as? ConnectSensorResultHandler_XiaoYu
        let disConnectHandler = params["disConnectHandler"] as? DisConnectSensorResultHandler_XiaoYu
        bluetoothHelper.connect(peripheral, options, connectHandler: connectHandler, disConnectHandler)
    }
    /// 断开与外设的连接
    @objc func Action_DisConnect(_ params:[AnyHashable:Any]) -> Void {
        bluetoothHelper.disConncet()
    }
    
}


extension Target_BC_BluetoothHelper{
    
    
    /// 实时模式
    @objc func Action_EnterRealTimeMode(_ params:[AnyHashable: Any]) -> Void {
        let state = params["state"] as? EnterRealTimeModelStateHandler
        let handler = params["handler"] as? EnterRealTimeModelDataHandler
        bluetoothHelper.enterRealTimeMode(state, handler)
    }
    /// 退出实时模式
    @objc func Action_ExitRealTimeModel(_ params:[AnyHashable: Any]) -> Void {
        bluetoothHelper.exitRealTimeModel()
    }
    
    
    /// 请求电池电量
    ///
    /// - Parameter params: 回调
    @objc func Action_RequestBatteryEnergy(_ params:[AnyHashable: Any]) -> Void {
        let handler = params["handler"] as? requestBattryEnergyHandler
        bluetoothHelper.requestBattryEnergy(handler)
    }
    
    /// 检查固件升级准备工作
    ///
    /// - Parameter handler: 回调
    @objc func Action_CheckPreparationForUpdateFirmware(_ params:[AnyHashable: Any]) -> Void {
        let handler = params["handler"] as? CheckPreparationForUpdateFirmwareHandler
        bluetoothHelper.checkPreparationForUpdateFirmware(handler)
    }
    /// 固件升级
    ///
    /// - Parameter params: 回调
    @objc func Action_UpdateFirmware(_ params:[AnyHashable: Any]) -> Void {
        let progressHandler = params["progressHandler"] as? UpdateFirmwareProgressHandler
        let handler = params["handler"] as? ReturnTheSameCommandHanler
        bluetoothHelper.updateFirmware(progressHandler, handler)
    }
    /// 请求版本号
    ///
    /// - Parameter handler: 回调
    @objc func Action_RequestVersion(_ params:[AnyHashable: Any]) -> Void {
        let handler = params["handler"] as? RequestVersionHandler
        bluetoothHelper.requestVersion(handler)
    }
    
    
    
   
    /// 读取MAC地址
    ///
    /// - Parameter handler: 回调
    @objc func Action_ReadMacAddress(_ params:[AnyHashable: Any]) -> Void {
        let handler = params["handler"] as? ReadMacAddressHandler
        bluetoothHelper.readMacAddress(handler)
    }
    
    
    /// 还原出厂设置
    ///
    /// - Parameter handler: 回调
    @objc func Action_ReStored(_ params:[AnyHashable: Any]) -> Void {
        let handler = params["handler"] as? ReturnTheSameCommandHanler
        bluetoothHelper.reStored(handler)
    }
    

    /// 传感器数据校准
    ///
    /// - Parameter handler: 回调
    @objc func Action_SensorCalibration(_ params:[AnyHashable: Any]) -> Void {
        let handler = params["handler"] as? SensorCorrectHandeler
        bluetoothHelper.sensorCalibration(handler)
    }
}
