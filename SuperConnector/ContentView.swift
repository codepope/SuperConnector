//
//  ContentView.swift
//  SuperConnector
//
//  Created by Dj Walker-Morgan on 22/11/2022.
//

import SwiftUI
import SWXMLHash

struct ContentView: View {
  var ipaddress="192.168.111.55"
  @State private var sessionid=""
  @State private var poweronoff=0
  @State private var volume: Double = 0
  
  var body: some View {
    VStack {
      HStack {
        Button(action: powerButtonPressed) {
          Image(systemName: poweronoff == 0 ? "radio" : "radio.fill" ).frame(width: 200,height: 200)
        }.frame(width:255,height:255).background(.blue).foregroundColor(.black)
        
      }
      Slider(value:$volume, in:0...20, onEditingChanged: { _ in
        Task {
//          await set(path:"netRemote.sys.audio.volume",value:Int(volume)) { xml in
//            print(xml)
//            guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
//            if status == "FS_OK" {
//
//            }
//          }
        }
      })
      Text("SuperConnector")
    }.onAppear {
      initialiseState()
    }
    .padding()
  }
  
  func powerButtonPressed() {
//    Task {
//      await set(path:"netRemote.sys.power",value: poweronoff==0 ? 1 : 0 ) { xml in
//        print(xml)
//        guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
//        if status == "FS_OK" {
//          poweronoff = poweronoff==0 ? 1 : 0
//        }
//      }
//    }
  }
  
  
  func initialiseState() {
    Task {
      let _ = try await sessionIdGet()
      print(sessionid)
      let powerxml=try await get("netRemote.sys.power")
      var status:String=powerxml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        poweronoff=Int(powerxml["fsapiResponse"]["value"]["u8"].element!.text) ?? 0
        print(poweronoff)
      }
      let volumexml=try await get("netRemote.sys.audio.volume")
      status=volumexml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        volume=Double(volumexml["fsapiResponse"]["value"]["u8"].element!.text) ?? 0.0
        print(volume)
      }
      let navstatusxml=try await set(path:"netRemote.nav.state",value:1)
      status=navstatusxml["fsapiResponse"]["status"].element?.text as? String ?? ""
      if status == "FS_OK" {
        let presetsxml=try await listGetNext(path:"netRemote.nav.presets")
        status=presetsxml["fsapiResponse"]["status"].element?.text as? String ?? ""
        if status == "FS_OK" {
          print(presetsxml)
        }
      }
    }
  }
  
  func sessionIdGet() async throws -> (String) {
    if sessionid == "" {
      
      let url=URL(string:"http://"+ipaddress+"/fsapi/CREATE_SESSION?pin=1234")!
      
      let (data, _) = try await URLSession.shared.data(from: url)
      
      //      print(String(decoding: data, as: UTF8.self))
      
      let xml = XMLHash.parse(data)

      sessionid=xml["fsapiResponse"]["sessionId"].element!.text
      
    }
    
    return sessionid
  }
  
  func get(_ path:String) async throws -> (XMLIndexer) {
    let _ = try await sessionIdGet()

    let url=URL(string:"http://"+ipaddress+"/fsapi/GET/"+path+"?pin=1234&sid="+sessionid)!

    let (data, _) = try await URLSession.shared.data(from: url)
 
    let xml=XMLHash.parse(data)
    
    return xml
  }
  

  func set(path:String, value:Int) async throws ->(XMLIndexer)  {
    let _ = try await sessionIdGet()
    
    let url=URL(string:"http://"+ipaddress+"/fsapi/SET/\(path)?pin=1234&sid=\(sessionid)&value=\(value)")
    
    let (data, _) = try await URLSession.shared.data(from: url!)
        
    let xml=XMLHash.parse(data)

    return xml
  }
  

  func listGetNext(path:String) async throws -> (XMLIndexer) {
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
