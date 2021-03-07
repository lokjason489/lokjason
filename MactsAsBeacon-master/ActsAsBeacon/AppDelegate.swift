//
//  ViewController.swift
//  macside
//
//  Created by CSIE on 2019/12/17.
//  Copyright © 2019 CSIE. All rights reserved.
//

import Cocoa
import CoreBluetooth
import IOBluetooth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static let storyboardName = "Main"
    
    private var window: NSWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {

        let mainVC = NSStoryboard(name: AppDelegate.storyboardName, bundle: nil).instantiateController(withIdentifier: CreateBeaconViewController.identifier) as? CreateBeaconViewController

        do {
            mainVC?.setViewModel(viewModel: CreateBeaconViewControllerVM(with: try createBeacon()))
        } catch {
            print(error)
        }

        let win = NSApplication.shared.windows[0]
        win.contentViewController = mainVC
    }

    func createBeacon() throws -> IBeacon {
        let userDef = UserDefaults()

        let uuid = userDef.uuid ?? IBeacon.defaultUUID
        let major = userDef.major ?? IBeacon.defaultMajor
        let minor = userDef.minor ?? IBeacon.defaultMinor
        let power = userDef.power ?? IBeacon.defaultPower

        return IBeacon(uuid: uuid, major: major, minor: minor, power: power)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
