//
//  ContentView.swift
//  SuperConnector
//
//  Created by Dj Walker-Morgan on 22/11/2022.
//

import SwiftUI
import SWXMLHash

struct ContentView: View {
  @Environment(\.scenePhase) var scenePhase
  
  
  var superDiscovery=ServiceDiscovery()
  
  struct Preset: Hashable {
    let key: Int
    let name: String
  }
  
  @State private var sessionid=""
  @State private var poweronoff=0
  @State private var volume: Double = 0
  @State private var presets: Array<Preset> = []
  @State private var displayLine="SuperConnector"
  
  @State private var ipaddress=""
  @State var firstAppear: Bool = true

  var body: some View {
    VStack {
      HStack {
        Button() {
          powerButtonPressed()
        } label: {
          Image(systemName: poweronoff == 0 ? "radio" : "radio.fill" ).resizable().scaledToFill().frame(maxWidth: .infinity,maxHeight: .infinity)
        }.buttonStyle(.bordered)
      }
      Slider(value:$volume, in:0...20, onEditingChanged: { _ in
        Task {
          let xml=try await set("netRemote.sys.audio.volume",value:Int(volume))
          guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
          if status == "FS_OK" {
            //print(xml)
          }
        }
      })
      Text(displayLine)
      List {
        ForEach(presets, id:\.key) { preset in
          Button(action: {
            selectPreset(presetNum: preset.key)
          }
          ) {
            Text(preset.name).frame(maxWidth:.infinity)
          }.buttonStyle(.borderedProminent)
        }
      }
    }.onChange(of: scenePhase) { newPhase in
      if newPhase == .active {
        initialiseState()
      } else if newPhase == .inactive {
        print("Inactive")
      } else if newPhase == .background {
        print("Background")
      } else {
        print(newPhase)
      }
    }//.onAppear() {
    //  initialiseState()
    //}
    
    .padding()
  }
  
  func selectPreset(presetNum:Int) {
    Task {
      let navstatusxml=try await set("netRemote.nav.state",value:1)
      let status=navstatusxml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        let _ = try await set("netRemote.nav.action.selectPreset",value:presetNum)
        //print(xml)
        getCurrentSelection()
      }
    }
  }
  
  func getCurrentSelection() {
    Task {
      sleep(1)
      let namexml=try await get("netRemote.play.info.name")
      //print(namexml)
      let status=namexml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        let name=namexml["fsapiResponse"]["value"]["c8_array"].element?.text as? String ?? ""
        displayLine=name
      }
    }
  }
  
  func powerButtonPressed() {
    Task {
      let xml=try await set("netRemote.sys.power",value: poweronoff==0 ? 1 : 0 )
      //print(xml)
      guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
      if status == "FS_OK" {
        poweronoff = poweronoff==0 ? 1 : 0
      }
      getCurrentSelection()
    }
  }
  
  func setIpaddress(address: String) {
    ipaddress=address
  }
  
  func initialiseState() {
    Task {
      //print("In Initialise State")
      while(superDiscovery.address=="") {
        sleep(1)
      }
      setIpaddress(address:superDiscovery.address)
      let _ = try await sessionIdGet()
      let powerxml=try await get("netRemote.sys.power")
      var status:String=powerxml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        poweronoff=Int(powerxml["fsapiResponse"]["value"]["u8"].element!.text) ?? 0
        //print(poweronoff)
      }
      let volumexml=try await get("netRemote.sys.audio.volume")
      status=volumexml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        volume=Double(volumexml["fsapiResponse"]["value"]["u8"].element!.text) ?? 0.0
        //print(volume)
      }
      let navstatusxml=try await set("netRemote.nav.state",value:1)
      status=navstatusxml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        presets.removeAll()
        let presetsxml=try await listGetNext("netRemote.nav.presets")
        status=presetsxml["fsapiResponse"]["status"].element?.text as? String ?? ""
        if status == "FS_OK" {
          _ = presetsxml["fsapiResponse"]["item"].all.map {elem in
            guard let stringkey=elem.element?.attribute(by:"key")?.text as? String else { return }
            let key=Int(stringkey)!
            guard let name=elem["field"]["c8_array"].element?.text as? String else { return }
            if name != "" {
              presets.append(Preset(key:key,name:name))
            }
          }
          getCurrentSelection()
        }
      }
    }
  }
  
  
  func sessionIdGet() async throws -> (String) {
    while sessionid == "" {
      
      let url=URL(string:"http://"+ipaddress+"/fsapi/CREATE_SESSION?pin=1234")!
      
      let (data, _) = try await URLSession.shared.data(from: url)
      
      //print(String(decoding: data, as: UTF8.self))
      
      let xml = XMLHash.parse(data)
      
      sessionid=xml["fsapiResponse"]["sessionId"].element!.text
      
    }
    
    return sessionid
  }
  
  func get(_ path:String) async throws -> (XMLIndexer) {
    let _ = try await sessionIdGet()
    //print("Getting ",path)
    let url=URL(string:"http://"+ipaddress+"/fsapi/GET/"+path+"?pin=1234&sid="+sessionid)!
    
    let (data, _) = try await URLSession.shared.data(from: url)
    
    let xml=XMLHash.parse(data)
    
    return xml
  }
  
  
  func set(_ path:String, value:Int) async throws ->(XMLIndexer)  {
    let _ = try await sessionIdGet()
    
    let url=URL(string:"http://"+ipaddress+"/fsapi/SET/\(path)?pin=1234&sid=\(sessionid)&value=\(value)")
    
    let (data, _) = try await URLSession.shared.data(from: url!)
    
    let xml=XMLHash.parse(data)
    
    return xml
  }
  
  
  func listGetNext(_ path:String) async throws -> (XMLIndexer) {
    let _ = try await sessionIdGet()
    
    let url=URL(string:"http://"+ipaddress+"/fsapi/LIST_GET_NEXT/\(path)/-1?pin=1234&sid=\(sessionid)&maxItems=10")
    
    let (data, _) = try await URLSession.shared.data(from: url!)
    
    let xml=XMLHash.parse(data)
    
    return xml
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
