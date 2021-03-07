//
//  AppDelegate.swift
//  macside
//
//  Created by CSIE on 2019/12/17.
//  Copyright © 2019 CSIE. All rights reserved.
//

import Cocoa
import Foundation
import CoreBluetooth
import IOBluetooth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static let storyboardName = "Main"
    
    private var window: NSWindowController!
    
    let sleep = """
    tell application "Finder" to sleep
    """
        let shutdown = """
    tell application "Finder" to shutdown
    """
    
    let spotifyplay = """
tell application "Spotify"
play track "spotify:playlist:6siwpwBkUee0vz4XEWpHNn"
end tell
"""
    let spotifypasue = """
tell application "Spotify"
pause
end tell
"""
    let spotifystart = """
tell application "spotify"
launch
end tell
"""
    
    func spotifyplaycontroller(){
        var out: NSAppleEventDescriptor?
        if let scriptObject = NSAppleScript(source: spotifyplay){
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict{
                print(error)
            }
        }
    }
    func spotifystopcontroller(){
        var out: NSAppleEventDescriptor?
        if let scriptObject = NSAppleScript(source: spotifypasue){
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict{
                print(error)
            }
        }
    }
    func spotifystartcontroller(){
        var out: NSAppleEventDescriptor?
        if let scriptObject = NSAppleScript(source: spotifystart){
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict{
                print(error)
            }
        }
    }

    func tosleep(){
        var out: NSAppleEventDescriptor?
        if let scriptObject = NSAppleScript(source: sleep){
            var errorDict: NSDictionary? = nil
            out = scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict{
                print(error)
            }
        }
    }
    
       func applicationDidFinishLaunching(_ notification: Notification) {
        let mainVC = NSStoryboard(name: AppDelegate.storyboardName, bundle: nil).instantiateController(withIdentifier:ViewController.identifier) as? ViewController
                  
                   do {
                             mainVC?.setViewModel(viewModel: ViewControllerVM(with: try createBeacon()))
                         } catch {
                             print(error)
                         }
              }

              func createBeacon() throws -> IBeacon {
                  let userDef = UserDefaults()

                  let uuid  = userDef.uuid ?? IBeacon.defaultUUID
                  let major = userDef.major ?? IBeacon.defaultMajor
                  let minor = userDef.minor ?? IBeacon.defaultMinor
                  let power = userDef.power ?? IBeacon.defaultPower

                  return IBeacon(uuid: uuid, major: major, minor: minor, power: power)
              }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

