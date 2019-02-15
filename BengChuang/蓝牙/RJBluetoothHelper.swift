//
//  BluetoothManager.swift
//  Pods-XiaoYu_Bluetooth_Example
//
//  Created by RJ on 2018/8/30.
//

import UIKit
@_exported import RJBluetooth_Mediator
import iOSDFULibrary
/// 网络环境 true 是生产环境 false s是测试环境
let NETWORK_ENVIRONMENT = true
let baseUrlString = NETWORK_ENVIRONMENT ? "http://appserv.coollang.com" : "http://mlf.f3322.net:83"
let firmwareUrlString = "VersionController/getLastVersion"



//新版操作服务和特征值
var kNewOperationServiceUUIDString = "0001"
var kNewCharacteristicWriteUUIDString   = "0002"
var kNewCharacteristicNotifyUUIDString  = "0003"
var kNewCharacteristicReadMacUUIDString = "0004"

/// 蓝牙指令
enum RJBluetoothCommadType : String {
    case None
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
/// 蓝牙断开连接类型
enum RJBluetoothDisconnnectType :String{
    case Active
    case UpdateFirmware
    case Passive
}

typealias SensorInfo = [String:Any]
typealias ScanSensorResultHandler_XiaoYu        = (_ peripherals:[SensorInfo])->Void
typealias ConnectSensorResultHandler_XiaoYu     = (_ success:Bool )->Void
typealias DisConnectSensorResultHandler_XiaoYu  = (_ success:Bool )->Void


/// 进入实时模式状态
typealias EnterRealTimeModelStateHandler = (_ success:Bool) -> Void
/// 进入实时模式后的蓝牙返回数据处理
typealias EnterRealTimeModelDataHandler = (_ responceValue:Data?) -> Void


/// 固件升级:准备工作
typealias CheckPreparationForUpdateFirmwareHandler = (_ info:[String:Any]?) -> Void
/// 固件升级:进度
typealias requestBattryEnergyHandler = (_ batteryEnergy:Int?) -> Void
/// 请求电池电量
typealias UpdateFirmwareProgressHandler = (_ progress:Double?) -> Void


/// 请求版本号
typealias RequestVersionHandler = (_ version:[String:Any]?) -> Void
/// 读取MAC地址
typealias ReadMacAddressHandler = (_ macAddress:String?) -> Void
/// 蓝牙指令原句返回
typealias ReturnTheSameCommandHanler = (_ success:Bool) -> Void
///传感器数据校准
typealias SensorCorrectHandeler = (_ bytes:Data?) -> Void

class RJBluetoothHelper: NSObject {
    
    /// 实时模式:进入状态
    var enterRealTimeModelStateHandler    :EnterRealTimeModelStateHandler?
    /// 实时模式:进入后的蓝牙返回数据处理
    var enterRealTimeModelDataHandler     : EnterRealTimeModelDataHandler?

    /// 固件升级:准备工作
    var checkPreparationForUpdateFirmwareHandler : CheckPreparationForUpdateFirmwareHandler?
    /// 固件升级:进度
    var updateFirmwareProgressHandler       : UpdateFirmwareProgressHandler?
    /// 固件升级:新版本固件模型
    var newFirmwareVersionModel             :RJFirmwareVersionModel?
    /// 固件升级:下载的固件地址
    var firmwareFilePath                    :URL?
    
    /// 请求电池电量
    var requestBattryEnergyHandler     : requestBattryEnergyHandler?
    /// 请求版本号
    var requestVersionHandler     : RequestVersionHandler?
    /// 读取MAC地址
    var readMacAddressHandler     : ReadMacAddressHandler?
    /// 蓝牙指令原句返回
    var returnTheSameCommandHanler     : ReturnTheSameCommandHanler?
    ///传感器数据校准
    var sensorCorrectHandeler         :SensorCorrectHandeler?
    
    /// 小羽设备搜索结果回调
    var scanSensorResultHandler_XiaoYu    : ScanSensorResultHandler_XiaoYu?
    /// 小羽连接设备回调
    var connectSensorResultHandler_XiaoYu : ConnectSensorResultHandler_XiaoYu?
    /// 处理设备连接结果
    let connectSensorResultHandler : ConnectSensorResultHandler         = {( central:CBCentralManager, peripheral :CBPeripheral, success:Bool ) in
        if success {
            //连接成功保存设备
            RJBluetoothHelper.shareInstance.connecterPeripheral = peripheral
            for sensor in RJBluetoothHelper.shareInstance.sensorList {
                if sensor.cbPeripheral == peripheral {
                    RJBluetoothHelper.shareInstance.connectedSensorModel = sensor
                }
            }
            //搜索设备服务
            RJBluetoothHelper.shareInstance.discoverServices(nil)
        }else{
            
        }
    }
    /// 小羽断开连接设备回调
    var disConnectSensorResultHandler_XiaoYu : DisConnectSensorResultHandler_XiaoYu?
    /// 处理设备断开连接结果
    let disConnectSensorResultHandler : DisConnectSensorResultHandler   = {( central:CBCentralManager,peripheral :CBPeripheral, error:Error? ) in
        RJBluetoothHelper.shareInstance.isConnected = false
        guard let coluse = RJBluetoothHelper.shareInstance.disConnectSensorResultHandler_XiaoYu else { return }
        coluse(error == nil)
        switch RJBluetoothHelper.shareInstance.disconncetType {
        case .Active:
            RJBluetoothHelper.shareInstance.connecterPeripheral = nil
        case .Passive:
            RJBluetoothHelper.shareInstance.reconnectForPassive()
        case .UpdateFirmware:
            RJBluetoothHelper.shareInstance.reconnectForUpdateFirmware()
        }
    }
    
    /// 单例
    static let shareInstance = RJBluetoothHelper()
    /// 中心设备管理器
    var centralManager : CBCentralManager?
    /// 新版本设备
    var isNewDevice = true
    /// 蓝牙断开连接类型 默认为被动断开连接
    var disconncetType :RJBluetoothDisconnnectType = .Passive
    /// 自动断线重连
    var autoReConnect = true
    
    /// 是否已连接外设
    var isConnected         :Bool = false
    /// 最远信号
    var minRSSI             :Int  = -100
    /// 过滤设备 允许显示的设备类型
    lazy var filter_OEM_TYPE : [OemType]  = {
        let array:[OemType] = [.F0]
        
        return array
    }()
    ///扫描到的外设
    private lazy var sensorList:[RJSensorModel] = {
        return [RJSensorModel]()
    }()
    /// 连接的外设
    var connecterPeripheral :CBPeripheral? {
        didSet{
            isConnected = connecterPeripheral != nil
        }
    }
    /// 连接的外设模型
    var connectedSensorModel : RJSensorModel?
    
    /// 要传递数据的特征值
    var writeCharacteristic : CBCharacteristic?
    /// 订阅的特征值
    var notifyCharacteristic : CBCharacteristic?
    /// 读的特征值
    var readCharacteristic : CBCharacteristic?
    
    
    /// 指令类型
    var commandType : RJBluetoothCommadType = .None
    /// 发送的指令
    var sendCommand :Data?
    /// 外设反馈的数据
    var feedbackValue = Data()
    
    /// 固件升级要发送的总包数
    var needSendPacketsOfFirmware :Int = 0
    /// 成功发送的固件升级包数目
    var successSendPacketsOfFirmware:Int = 0
    
    
    /// DTW 的数据总包数 = 数据总包数
    var DTWCount :Int = 0
    
}
//MARK: - 设备连接
extension RJBluetoothHelper {
    
    /// 是否可以断线重连
    ///
    /// - Parameter ReConnect: 重连 布尔值
    func autoReConnect(_ ReConnect:Bool) -> Void {
        autoReConnect = ReConnect
    }
    //MARK: 搜索外设
    /// 搜索外设
    func scanSensor(withServices services: [CBUUID]?, options: [String:Any]? , handler:ScanSensorResultHandler_XiaoYu? ) -> Void {
        scanSensorResultHandler_XiaoYu  = handler
        /// 处理设备搜索结果
        let scanSensorResultHandler : ScanSensorResultHandler               = {(central:CBCentralManager, peripheral: CBPeripheral, advertisementData: [String : Any],RSSI: NSNumber) in
            self.centralManager = central
            //1.过滤外设
            let result = self.filterSensor(withRSSI: RSSI, AdvertisementData: advertisementData)
            if !result {
                return
            }
            
            //2.创建外设模型对象
            let sensorModel = RJSensorModel.init(peripheral, advertisementData, RSSI)
            //3.添加对象
            let sensorInfos =  self.addSensorModel(sensorModel)
            guard let coluse = self.scanSensorResultHandler_XiaoYu else { return }
            coluse(sensorInfos)
        }
        CTMediator.scanSensor(withServices: services, options: options, handler: scanSensorResultHandler)
    }
    //过滤外设
    private func filterSensor(withRSSI RSSI: NSNumber, AdvertisementData: [String : Any]) -> Bool {
        //1.过滤 信号差的
        if RSSI.intValue < minRSSI {
            return false
        }
        //2.过滤 OEM_ID 不匹配的
        guard let advertisementDataManufacturerData = AdvertisementData[CBAdvertisementDataManufacturerDataKey] else { return false }
        let manufacturerData = advertisementDataManufacturerData as! Data
        guard let manufacturerString = String(data: manufacturerData.prefix(upTo: 6), encoding:.utf8) else { return false }
        
        for index in 0 ..< filter_OEM_TYPE.count {
            let oemType = filter_OEM_TYPE[index]
            if manufacturerString.contains(oemType.rawValue) {
                return true
            }
        }
        return false
    }
    //添加数组对象
    private func addSensorModel(_ sensorModel:RJSensorModel) -> [SensorInfo] {
        //1.根据外设名称判断是否已包含该外设
        var hadContain = false
        
        for index in 0 ..< sensorList.count {
            let model = sensorList[index]
            if model.name == sensorModel.name {
                hadContain = true
            }
            
        }
        //2.根据是否包含 跟新外设表
        if hadContain { //包含
            for index in 0 ..< sensorList.count {
                let model = sensorList[index]
                if model.name == sensorModel.name {
                    sensorList[index] = sensorModel
                }
                
            }
        }else{//不包含
            sensorList.append(sensorModel)
        }
        //3.将外设表 按RSSI 大小排序
        sensorList.sort {$0.RSSI < $1.RSSI}
        var sensorInfos = [SensorInfo]()
        for sensorModel in sensorList {
            sensorInfos.append(sensorModel.infoDic())
        }
        return sensorInfos
    }
    /// 搜索外设
    func scanSensorWithOriginData(withServices services: [CBUUID]?, options: [String:Any]? , handler:ScanSensorResultHandler? ) -> Void {
        CTMediator.scanSensor(withServices: services, options: options, handler: handler)
    }
    //MARK: 结束搜索外设
    /// 结束搜索外设
    func stopScan() -> Void {
        CTMediator.stopScan()
    }
    //MARK: 连接外设
    /// 连接外设
    ///
    /// - Parameters:
    ///   - sensor: 外设模型
    ///   - options: 可选字典，指定用于连接状态的提示的选项
    func connect(_ peripheral:CBPeripheral, _ options:[String : Any]? ,connectHandler:ConnectSensorResultHandler_XiaoYu? , _ disConnectHandler:DisConnectSensorResultHandler_XiaoYu?) -> Void {
        connectSensorResultHandler_XiaoYu = connectHandler
        disConnectSensorResultHandler_XiaoYu = disConnectHandler
        
        CTMediator.connect(peripheral, options, connnectHandler: connectSensorResultHandler, disConnectSensorResultHandler)
    }
    /// 搜索服务
    ///
    /// - Parameter serviceUUIDs: 服务数组
    func discoverServices( _ serviceUUIDs:[CBUUID]?) -> Void {
        /// 处理搜索设备服务结果
        let discoverServicesHandler : DiscoverServicesHandler               = {( peripheral :CBPeripheral , error: Error?) in
            guard let services = peripheral.services else { return }
            print("搜索服务 : \(String(describing: peripheral.services)) 成功")
            //遍历服务数组找到指定的服务
            for index in 0 ..< services.count {
            let service = services[index]
            self.discoverCharacteristics(nil, for:service)
            }
        }
        CTMediator.discoverServices(serviceUUIDs, discoverServicesHandler)
    }
    /// 搜索设备服务特征值
    ///
    /// - Parameters:
    ///   - characteristicUUIDs: 特征值
    ///   - service: 服务
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) -> Void {
        /// 处理搜索设备服务特征值结果
        let discoverCharacteristicsHandler : DiscoverCharacteristicsHandler = {( peripheral: CBPeripheral, service: CBService,              error:Error?) in
            guard let characteristics = service.characteristics else { return }
            print("搜索特征值 : \(String(describing: service.characteristics)) 成功")
            //遍历特征值数组找到对应特征值
            for index in 0 ..< characteristics.count {
                let characteristic = characteristics[index]
                self.handleCharacteristic(characteristic)
            }
        }
        CTMediator.discoverCharacteristics(characteristicUUIDs, for: service, discoverCharacteristicsHandler)
    }
    func handleCharacteristic(_ characteristic:CBCharacteristic) -> Void {
        //读MacAddress 特征值
        if  characteristic.uuid .isEqual(CBUUID(string: kNewCharacteristicReadMacUUIDString)){
            readValue(for: characteristic)
        }
        //写数据 特征值
        if  characteristic.uuid .isEqual(CBUUID(string: kNewCharacteristicWriteUUIDString)){
            writeCharacteristic = characteristic
        }
        //订阅 特征值
        if  characteristic.uuid .isEqual(CBUUID(string: kNewCharacteristicNotifyUUIDString)){
            setNotifyValue(true, for: characteristic)
        }
    }
    /// 读取设备服务特征值
    ///
    /// - Parameters:
    ///   - characteristic: 要读的特征值
    ///   - handler: 回调
    func readValue(for characteristic: CBCharacteristic) -> Void {
        /// 处理读取设备服务特征值结果
        let readValueHandler : ReadValueHandler                             = {( peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) in
            if error == nil {
                self.readCharacteristic = characteristic
                print("读取MacAddress成功")
                guard let value = characteristic.value else { return }
                self.connectedSensorModel?.MacAdress = String(data: value, encoding: .utf8)
            }
        }
        CTMediator.readValue(for: characteristic,readValueHandler)
    }
    /// 订阅设备服务特征值
    ///
    /// - Parameters:
    ///   - enabled: 当启用通知/指示时，将通过委托方法接收特征值的更新
    ///   - characteristic: 要订阅的特征值
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) -> Void {
        /// 处理订阅设备服务特征值结果
        let setNotifyValueHandler : SetNotifyValueHandler                   = {( peripheral: CBPeripheral, characteristic: CBCharacteristic, error: Error?) in
            if error == nil {
                self.notifyCharacteristic = characteristic
                self.determineConnectState()
                print("订阅成功")
            }
        }
        CTMediator.setNotifyValue(enabled, for: characteristic, setNotifyValueHandler)
    }
    /// 判断连接是否真实成功 : 要获取到对应的特征值才算连接成功
    private func determineConnectState() -> Void {
        guard let coluse = self.connectSensorResultHandler_XiaoYu else { return }
        if notifyCharacteristic != nil && writeCharacteristic != nil {
            coluse(true)
            disconncetType = .Passive
        }else{
            coluse(false)
        }
    }
    //MARK: 断开与外设的连接
    /// 断开与外设的连接
    func disConncet() -> Void {
        disconncetType = .Active
        CTMediator.disConnect()
        readCharacteristic   = nil
        notifyCharacteristic = nil
        writeCharacteristic  = nil
    }
    //MARK: - 断线重连
    /// 断线重连：被动
    func reconnectForPassive() -> Void {
        if autoReConnect {
            guard let peripheral = connecterPeripheral else {return}
            connect(peripheral, nil, connectHandler: connectSensorResultHandler_XiaoYu, disConnectSensorResultHandler_XiaoYu)
        }
    }
    /// 断线重连：固件升级
    func reconnectForUpdateFirmware() -> Void {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.downloadNewFirmware()
        }
    }
}

extension RJBluetoothHelper {
    
    //MARK: - 创建指令
    
    /// 创建蓝牙指令
    ///
    /// - Parameters:
    ///   - headCode: 帧头
    ///   - functionCode: 功能码
    ///   - validData: 参数数据
    ///   - length: 字节长度
    /// - Returns: 蓝牙指令
    private func createCommad(_ functionCode:[UInt8]?  ,_ validData:[UInt8]?  , length:Int) -> Data {
        var bytes = [UInt8]()
        
        //1.添加帧
        bytes.append(contentsOf: [0xA8])
        //2.添加功能码
        guard let function = functionCode else { return Data() }
        bytes.append(contentsOf: function)
        //3.是否有数据参数发送
        //3.1 无参数 创建指令
        guard let valid = validData  else { return creatData(value: bytes ,length: length) }
        //3.2 有参数 添加参数数据
        bytes.append(contentsOf: valid)
        return creatData(value: bytes ,length: length)
    }
    //和校验
    private func creatData(value:[UInt8] , length:Int) -> Data {
        
        // 无数字位已0补足
        var bytes = value
        for _ in bytes.count ..< length {
            bytes.append(0x00)
        }
        // 校验和
        var count = 0
        for index in 0 ..< bytes.count {
            let num = Int(bytes[index])
            count += num
        }
        let verifyCode = UInt8(count & 0xFF)
        bytes[19] = verifyCode
        return Data(bytes: bytes)
    }
    //MARK: - 发送指令
    /// 发送指令
    ///
    /// - Parameter type: 指令类型
    func sendCommand(_ command:Data?) -> Void {
        if !isConnected {
            return
        }
        sendCommand  = command
        /// 处理发送指令
        let sendCommandResultHandler:SendCommandResultHandler               = {( peripheral: CBPeripheral, characteristic: CBCharacteristic,  error: Error?)  in
            RJBluetoothHelper.shareInstance.handleSendCommadResult(characteristic.value, error)
        }
        /// 处理外设反馈的数据
        let receiveCommandResultHandler:ReceiveCommandResultHandler         = {( peripheral: CBPeripheral, value: Data,  error: Error?)  in
            RJBluetoothHelper.shareInstance.handleFeedback(value, error)
        }
        CTMediator.sendConmand(sendCommand, for: writeCharacteristic,.withResponse, sendCommandResultHandler, receiveCommandResultHandler)
    }
    //MARK: - 处理发送指令结果
    /// 处理发送指令结果
    ///
    /// - Parameters:
    ///   - value: 发送的数据
    ///   - error: 错误
    func handleSendCommadResult(_ value:Data? , _ error:Error?) -> Void {
        
        if error == nil{
            print("\(RJBluetoothHelper.shareInstance.commandType.rawValue)指令发送成功\(sendCommand!)")
            //            dump(sendCommand)
        }else{
            print("\(RJBluetoothHelper.shareInstance.commandType.rawValue)指令发送失败\n\(String(describing: error))")
        }
    }
    
    //MARK: - 处理蓝牙对指令反馈数据
    /// 处理蓝牙对指令反馈数据
    ///
    /// - Parameters:
    ///   - value: 返回的数据
    ///   - error: 错误
    func handleFeedback(_ value:Data? , _ error:Error?) -> Void {
        guard let data = value else { return  }
        if error == nil{
            print(Thread.current)
            //            dump(data)
            print("接收\(RJBluetoothHelper.shareInstance.commandType.rawValue)指令返回数据成功\(data)")
            
        }else{
            print("接收\(RJBluetoothHelper.shareInstance.commandType.rawValue)指令返回数据失败\n\(String(describing: error))")
        }
        
        let helper = RJBluetoothHelper.shareInstance
        helper.feedbackValue = data
        switch helper.commandType {
        case .None:
            break
        case .EnterRealTimeMode:
            hanleEnterRealTimeModelFeedbackData()
        case .RequestBatteryEnergy:
            hanleRequestBatteryEnergyFeedbackData()
        case .RequestVersion:
            hanleRequestVersionFeedbackData()
        case .UpdateFirmware:
            handleUpdateFirmwareFeedbackData()
        case .ReadMacAddress:
            hanleReadMacAddressFeedbackData()
        case .ReStored:
            handleReturnTheSameCommandFeedbackData()
        case .ExitRealTimeModel:
            break
        case .SensorCorrect:
            hanleSensorCalibrationFeedbackData()
        default:
            break
        }
    }
    
}

//MARK: - 功能码
extension RJBluetoothHelper :DFUProgressDelegate , DFUServiceDelegate{
    
    
    //MARK: - 请求电池电量
    /// 请求电池电量
    ///
    /// - Parameter handler: 回调
    func requestBattryEnergy(_ handler:requestBattryEnergyHandler?) -> Void {
        requestBattryEnergyHandler = handler
        sendCommand(createRequestBatteryEnergyCommand())
    }
    private func createRequestBatteryEnergyCommand() -> Data? {
        commandType = .RequestBatteryEnergy
        return createCommad([0x22], nil, length: 20)
    }
    private func hanleRequestBatteryEnergyFeedbackData() -> Void {
        guard let handler = requestBattryEnergyHandler else { return }
        let bytes = [UInt8](feedbackValue)
        let energy = Int(bytes[2])
        handler(energy)
    }
    //MARK: - 请求版本号
    /// 请求版本号
    ///
    /// - Parameter handler: 回调
    func requestVersion(_ handler:RequestVersionHandler?) -> Void {
        requestVersionHandler = handler
        sendCommand(createRequestVersionCommand())
    }
    private func createRequestVersionCommand() -> Data? {
        commandType = .RequestVersion
        return createCommad([0x21], nil, length: 20)
    }
    private func hanleRequestVersionFeedbackData() -> Void {
        guard let handler = requestVersionHandler else { return }
        let versionData = feedbackValue.subdata(in: 2 ..< 17)
        let version = String(data: versionData, encoding: .utf8)
        var infoDic = [String:Any]()
        infoDic["version"] = version
        handler(infoDic)
    }

    //MARK: - 固件升级
    func checkPreparationForUpdateFirmware(_ preparationHandler:CheckPreparationForUpdateFirmwareHandler?) -> Void {
        checkPreparationForUpdateFirmwareHandler = preparationHandler
        checkDeviceVersion()
    }
    private func checkDeviceVersion() -> Void {
        if isNewDevice {
            checkBattryEnergy()
        }else{
            guard let colsure = self.checkPreparationForUpdateFirmwareHandler else {return}
            var info = [String:Any]()
            info["state"]          = false
            info["description"]    = "已是最新版本固件"
            colsure(info)
        }
    }
    private func checkBattryEnergy() -> Void {
        requestBattryEnergy { (energy:Int?) in
            var info = [String:Any]()
            guard let colsure = self.checkPreparationForUpdateFirmwareHandler else {return}
            guard let battery = energy else {
                info["state"]          = false
                info["description"] = "未能获取电量"
                colsure(info)
                return
            }
            if battery <= 50 {
                info["state"]          = false
                info["description"] = "电量不足"
                colsure(info)
            }else{
                self.checkFirmwareVersion()
            }
        }
    }
    private func checkFirmwareVersion() -> Void {
        requestVersion { (versionInfoDic:[String:Any]?) in
            var info = [String:Any]()
            guard let colsure = self.checkPreparationForUpdateFirmwareHandler else {return}
            guard let versionInfo = versionInfoDic else {
                info["state"]          = false
                info["description"] = "未能获取当前设备版本"
                colsure(info)
                return
            }
            guard let versionAny = versionInfo["version"]  else {
                info["state"]          = false
                info["description"] = "未能获取当前设备版本"
                colsure(info)
                return
            }
            let versionString = versionAny as! String
            let arr = versionString.components(separatedBy: "-")
            let currentVersion = arr[0]
            self.requsetNewFirmwareVersion(currentVersion)
        }
    }
    func requsetNewFirmwareVersion(_ currentVersion:String) -> Void {
        guard let colsure = self.checkPreparationForUpdateFirmwareHandler else {return}
        var info = [String:Any]()
        let urlString = baseUrlString + "/" + firmwareUrlString
        guard let url = URL(string: urlString) else {
            info["state"]          = false
            info["description"] = "请求最新版本的URL丢失"
            colsure(info)
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "oemType=\(connectedSensorModel!.correctOrderOemType())&lang=\(currentLanguage())&appCommonVersion=3".data(using: .utf8)
        urlRequest.httpShouldHandleCookies = true
        let configuration = URLSessionConfiguration.default
        let manager = URLSession(configuration: configuration)
        let task = manager.dataTask(with: urlRequest) { (data:Data?, resonce:URLResponse?, error:Error?) in
            let nerVersionModel = RJFirmwareVersionModel(self.getNewVersionInfiDic(data))
            self.newFirmwareVersionModel = nerVersionModel
            DispatchQueue.main.async {
                self.wetherUpdate(currentVersion, newVersion: nerVersionModel.Version ?? "")
            }
        }
        task.resume()
    }
    private func currentLanguage() -> String {
        let languages = Locale.preferredLanguages
        let language = languages[0]
        if language.contains("zh-Hans") {
            return language
        }else if language.contains("id") {
            return language
        }
        return "english"
    }
    
    private func getNewVersionInfiDic(_ data:Data?) -> [String:Any]? {
        guard let result = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) else {return nil}
        let resultDic = result as! [String:Any]
        let ret = resultDic["ret"]
        let errDesc = resultDic["errDesc"]
        if ret is String {
            let retString = ret as! String
            if retString == "0" {
                if errDesc is [String : Any] {
                    return  errDesc as? [String : Any]
                }
            }
        }
        return nil
        
    }
    func wetherUpdate(_ currentVersion:String , newVersion: String) -> Void{
        guard let colsure = self.checkPreparationForUpdateFirmwareHandler else {return}
        var info = [String:Any]()
        if currentVersion.count != newVersion.count || currentVersion.count != 6 {
            info["state"]          = false
            info["description"]    = "版本信息错误"
        }
        let currenrVersionArray = String(currentVersion.suffix(5)).components(separatedBy: ".")
        let newVersionArray     = String(currentVersion.suffix(5)).components(separatedBy: ".")
        var update = false
        
        for index in 0 ..< currenrVersionArray.count {
            if Int(newVersionArray[index])! > Int(currenrVersionArray[index])! {
                update = true
            }
        }
        if update {
            info["state"]          = true
            info["currentVersion"] = currentVersion
            info["newVersion"]     = newVersion
        }else{
            info["state"]          = false
            info["description"]    = "已经是最新版本"
        }
        colsure(info)
        
    }
    func updateFirmware(_ progressHandler:UpdateFirmwareProgressHandler? , _ handler:ReturnTheSameCommandHanler?) -> Void {
        returnTheSameCommandHanler = handler
        updateFirmwareProgressHandler = progressHandler
        sendCommand(createUpdateFirmwareCommand())
        //        downloadNewFirmware()
    }
    private func createUpdateFirmwareCommand() -> Data? {
        commandType = .UpdateFirmware
        var functionCode : [UInt8]?
        let omeType = connectedSensorModel!.oemType!
        switch omeType {
        case .F0:
            functionCode = [0x05]
        }
        
        return createCommad(functionCode, [0x0F], length: 20)
    }
    private func handleUpdateFirmwareFeedbackData() -> Void {
        if sendCommand == feedbackValue {
            disconncetType = .UpdateFirmware
        }else{
            guard let colsure = returnTheSameCommandHanler else {return}
            colsure(false)
        }
    }
    
    func downloadNewFirmware() -> Void {
        let path = newFirmwareVersionModel?.Path ?? ""
        guard let url = URL(string: path) else { return  }
        let configuration = URLSessionConfiguration.default
        let manager = URLSession(configuration: configuration)
        let downloadTask = manager.downloadTask(with: url) { (filePath:URL?, responce:URLResponse?, error:Error?) in
            let documentsDirectoryURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let newFilePath = documentsDirectoryURL?.appendingPathComponent((responce?.suggestedFilename)!)
            try? FileManager.default.moveItem(at: filePath!, to: newFilePath!)
            self.firmwareFilePath = newFilePath
            DispatchQueue.main.async {
                self.updateWithiniOSDFULirary()
            }
        }
        downloadTask.resume()
    }
    private func updateWithiniOSDFULirary() -> Void {
        let selectFirmware = DFUFirmware(urlToBinOrHexFile:firmwareFilePath! , urlToDatFile: nil, type: .application)
        
        let initiator = DFUServiceInitiator(centralManager: centralManager!, target: connecterPeripheral!).with(firmware: selectFirmware!)
        initiator.progressDelegate = self
        initiator.delegate         = self
        let _ = initiator.start()
    }
    
    func updateFirmwareSuccess() -> Void {
        returnTheSameCommandHanler!(true)
        CTMediator.resetCBCentralManagerDelegate()
        //        connect(connecterPeripheral!, nil, connectHandler: connectSensorResultHandler_XiaoYu, disConnectSensorResultHandler_XiaoYu)
    }
    
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .completed:
            print("升级完成")
            updateFirmwareSuccess()
        default:
            break
        }
    }
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print("\(message)")
    }
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        updateFirmwareProgressHandler!(Double(progress)/100.0)
    }
    
    
    
    
    
    //MARK: - 进入实时模式
    /// 进入实时模式
    ///
    /// - Parameter handler: 回调
    func enterRealTimeMode(_ state:EnterRealTimeModelStateHandler? ,_ handler:EnterRealTimeModelDataHandler?) -> Void {
        enterRealTimeModelStateHandler = state
        enterRealTimeModelDataHandler  = handler
        sendCommand(createEnterRealTimeModelCommand())
    }
    func createEnterRealTimeModelCommand() -> Data? {
        commandType = .EnterRealTimeMode
        return createCommad([0x24], [0x11], length: 20)
    }
    private func hanleEnterRealTimeModelFeedbackData() -> Void {
        hanleEnterRealTimeModelDataOfUpLoadSwingSportFeedbackData()
        
    }
    private func hanleEnterRealTimeModelDataOfUpLoadSwingSportFeedbackData() -> Void {
        guard let handler = enterRealTimeModelDataHandler else { return }
//        let bytes = [UInt8](feedbackValue)
        
        handler(feedbackValue)
    }
    //MARK: - 退出实时模式
    /// 退出实时模式
    func exitRealTimeModel() -> Void {
        commandType = .ExitRealTimeModel
        sendCommand(createExitRealTimeModelCommand())
    }
    private func createExitRealTimeModelCommand() -> Data? {
        return createCommad([0x24], [0x02], length: 20)
    }
    //MARK: - 详情界面
    
    
    
    /// 读取MAC地址(2.0有效)
    ///
    /// - Parameter handler: 回调
    func readMacAddress(_ handler:ReadMacAddressHandler?) -> Void {
        readMacAddressHandler = handler
        sendCommand(createReadMacAddressCommand())
    }
    private func createReadMacAddressCommand() -> Data? {
        commandType = .ReadMacAddress
        return createCommad([0xA3], nil, length: 20)
    }
    func hanleReadMacAddressFeedbackData() -> Void {
        guard let handler = readMacAddressHandler else { return }
        let macData = feedbackValue.subdata(in: 3..<15)
        let macAddress = String(data: macData, encoding: .utf8)
        handler(macAddress)
    }
    
    
    //MARK: - 还原出厂设置
    /// 还原出厂设置
    ///
    /// - Parameter handler: 回调
    func reStored(_ handler:ReturnTheSameCommandHanler?) -> Void {
        returnTheSameCommandHanler = handler
        sendCommand(createReStoredCommand())
    }
    private func createReStoredCommand() -> Data? {
        commandType = .ReStored
        return createCommad([0x04], [0x00], length: 20)
    }

    /// 统一处理原句返回的蓝牙反馈指令
    func handleReturnTheSameCommandFeedbackData() -> Void {
        guard let handler = returnTheSameCommandHanler else { return }
        handler(sendCommand == feedbackValue)
    }
    
    
    //MARK: - 请求版本号
    /// 请求版本号
    ///
    /// - Parameter handler: 回调
    func sensorCalibration(_ handler:SensorCorrectHandeler?) -> Void {
        sensorCorrectHandeler = handler
        sendCommand(createSensorCalibration())
    }
    private func createSensorCalibration() -> Data? {
        commandType = .RequestVersion
        return createCommad([0x21], [0xE1], length: 20)
    }
    private func hanleSensorCalibrationFeedbackData() -> Void {
        guard let handler = sensorCorrectHandeler else { return }
//        let bytes = [UInt8](feedbackValue)
        handler(feedbackValue)
    }
}

