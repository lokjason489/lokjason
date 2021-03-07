//
//  ViewController.swift
//  iphoneside
//
//  Created by CSIE on 2019/12/17.
//  Copyright © 2019 CSIE. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate,CLLocationManagerDelegate{
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var range1: UILabel!
    @IBOutlet weak var widerange: UILabel!
    @IBOutlet weak var subswitch: UISwitch!
    
    // 自訂一個錯誤型態
    enum SendDataError: Error {
        case CharacteristicNotFound
    }
    
    // GATT
    let C001_CHARACTERISTIC = "C001"
    var centralManager: CBCentralManager!
    // 儲存連上的 peripheral，此變數一定要宣告為全域
    var connectPeripheral: CBPeripheral!
    // 記錄所有的 characteristic
    var charDictionary = [String: CBCharacteristic]()
    
    //Beacon
    let locationManager = CLLocationManager()
    
    func isPaired() -> Bool {
        let user = UserDefaults.standard
        if let uuidString = user.string(forKey: "KEY_PERIPHERAL_UUID") {
            let uuid = UUID(uuidString: uuidString)
            let list = centralManager.retrievePeripherals(withIdentifiers: [uuid!])
            if list.count > 0 {
                connectPeripheral = list.first!
                connectPeripheral.delegate = self
                return true
            }
        }
        return false
    }
    
    func monitorBeacon(){
            let uuid = UUID(uuidString: "B0702880-A295-A8AB-F734-031A98A512DE")
            let region = CLBeaconRegion(uuid: uuid!, identifier: "macside")
            locationManager.startRangingBeacons(satisfying: region.beaconIdentityConstraint)
            self.textView.text =  "startBeacon"
            locationManager.startMonitoring(for: region)
    }
    
    func closeBeacon(){
        let uuid = UUID(uuidString: "B0702880-A295-A8AB-F734-031A98A512DE")
        let region = CLBeaconRegion(uuid: uuid!, identifier: "macside")
        self.textView.text = self.textView.text + "\n" + "stopBeacon"
        locationManager.stopMonitoring(for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons{
            print("major=\(beacon.major) minor=\(beacon.minor) accury=\(beacon.accuracy) rssi=\(beacon.rssi)")
            switch beacon.proximity {
            case .immediate:
                print("immediate")
                range1.text = "immediate"
            case .far:
                print("far")
                range1.text = "far"
                let string = "sleep"
                       do {
                           let data = string.data(using: .utf8)
                           try sendData(data!, uuidString: C001_CHARACTERISTIC, writeType: .withResponse)
                       } catch {
                           print(error)
                       }
            case .near:
                print("near")
                range1.text = "near"
            case .unknown:
                print("unknown")
                range1.text = "unknown"
            @unknown default:
                range1.text = "@unknown default"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        let queue = DispatchQueue.global()
        // 將觸發1號method
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    /* 1號method */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // 先判斷藍牙是否開啟，如果不是藍牙4.x ，也會傳回電源未開啟
        guard central.state == .poweredOn else {
            // iOS 會出現對話框提醒使用者
            return
        }
        
        if isPaired() {
            // 將觸發 3號method
            centralManager.connect(connectPeripheral, options: nil)

        } else {
            // 將觸發 2號method
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    /* 2號method */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name else {
            return
        }
        print("找到藍牙裝置: \(deviceName)")
        
        guard deviceName.range(of: "macside") != nil || deviceName.range(of: "MacBook") != nil
        else {
            return
        }
        
        central.stopScan()
        
        // 斷線處理
        // 儲存周邊端的UUID，重新連線時需要這個值
        let user = UserDefaults.standard
        user.set(peripheral.identifier.uuidString, forKey: "KEY_PERIPHERAL_UUID")
        user.synchronize()
        
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        
        // 將觸發 3號method
        centralManager.connect(connectPeripheral, options: nil)
    }
    
    /* 3號method */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 清除上一次儲存的 characteristic 資料
        charDictionary = [:]
        // 將觸發 4號method
        peripheral.discoverServices(nil)
    }
    
    /* 4號method */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("ERROR: \(#function)")
            print(error!.localizedDescription)
            return
        }
        
        for service in peripheral.services! {
            // 將觸發 5號method
            connectPeripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /* 5號method */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#function)")
            print(error!.localizedDescription)
            return
        }
        
        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print("找到: \(uuidString)")
        }
    }
    
    /* 將資料傳送到 peripheral */
    func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType) throws {
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        
        connectPeripheral.writeValue(
            data,
            for: characteristic,
            type: writeType
        )
    }

    /* 將資料傳送到 peripheral 時如果遇到錯誤會呼叫 */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("寫入資料錯誤: \(error!)")
        }
    }
    
    /* 取得 peripheral 送過來的資料 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#function)")
            print(error!)
            return
        }
        
        if characteristic.uuid.uuidString == C001_CHARACTERISTIC {
            let data = characteristic.value! as NSData
            let string = "> " + String(data: data as Data, encoding: .utf8)!
            print(string)

            DispatchQueue.main.async {
                if self.textView.text.isEmpty {
                    self.textView.text = string
                } else {
                    self.textView.text = self.textView.text + "\n" + string
                }
            }
        }
    }

    /* 訂閱與取消訂閱開關 */
    @IBAction func subscribeValue(_ sender: UISwitch) {
        if charDictionary[C001_CHARACTERISTIC] != nil{
            connectPeripheral.setNotifyValue(sender.isOn, for: charDictionary[C001_CHARACTERISTIC]!)
            monitorBeacon()
        }
        else{
            subswitch.setOn(false, animated: true)
            textView.text = textView.text + "\n" + "can't find MAC"
        }
    }
    
    /* 按下送出按鈕 */
    @IBAction func sendClick(_ sender: Any) {
        let string = textField.text ?? ""
        if textView.text.isEmpty {
            textView.text = string
        } else {
            textView.text = textView.text + "\n" + string
        }
        textField.text = ""
        do {
            let data = string.data(using: .utf8)
            // 注意這裡必須根據 characteristic 的屬性設定
            // 來決定使用 withoutResponse 或是 withResponse
            try sendData(data!, uuidString: C001_CHARACTERISTIC, writeType: .withResponse)
        } catch {
            print(error)
        }
    }
    
    /* 向 periphral 送出讀資料請求 */
    @IBAction func readDataClick(_ sender: Any) {
        let characteristic = charDictionary[C001_CHARACTERISTIC]!
        connectPeripheral.readValue(for: characteristic)
    }
    
    /* 關閉鍵盤 */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.3) {
            self.view.endEditing(true)
        }
    }
    
    /* 斷線處理 */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("連線中斷")
        if isPaired() {
            // 將觸發 3號method
            centralManager.connect(connectPeripheral, options: nil)
        }
    }
    
    /* 解配對 */
    func unpair() {
        let user = UserDefaults.standard
        closeBeacon()
        user.removeObject(forKey: "KEY_PERIPHERAL_UUID")
        user.synchronize()
        centralManager.cancelPeripheralConnection(connectPeripheral)
        // 在 iOS 中要提醒使用者必須從系統設定中「忘記裝置」，否則無法再配對
    }

    @IBAction func sleepClick(_ sender: Any) {
        let string = "sleep"
        
        do {
            let data = string.data(using: .utf8)
            // 注意這裡必須根據 characteristic 的屬性設定
            // 來決定使用 withoutResponse 或是 withResponse
            try sendData(data!, uuidString: C001_CHARACTERISTIC, writeType: .withResponse)
        } catch {
            print(error)
        }
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let content = UNMutableNotificationContent()
        content.title = "注意"
        content.subtitle = "near to mac"
        content.badge = 1
        content.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: nil)
      UNUserNotificationCenter.current().add(request,withCompletionHandler:nil)
        widerange.text="in region"
        if CLLocationManager.isRangingAvailable(){
            locationManager.startRangingBeacons(in: region as! CLBeaconRegion)
            
        }
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let content = UNMutableNotificationContent()
          content.title = "注意"
          content.subtitle = "far to mac"
          content.badge = 1
          content.sound = UNNotificationSound.default
          let request = UNNotificationRequest(identifier: "notification", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request,withCompletionHandler:nil)
        let string = "sleep"
        do {
            let data = string.data(using: .utf8)
            try sendData(data!, uuidString: C001_CHARACTERISTIC, writeType: .withResponse)
        } catch {
            print(error)
        }
        widerange.text="out of region"
        locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
    }

}



