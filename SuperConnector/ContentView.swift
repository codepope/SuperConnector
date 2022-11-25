//
//  ContentView.swift
//  SuperConnector
//
//  Created by Dj Walker-Morgan on 22/11/2022.
//

import SwiftUI
import Alamofire
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
          await set(path:"netRemote.sys.audio.volume",value:Int(volume)) { xml in
            print(xml)
            guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
            if status == "FS_OK" {
              
            }
          }
        }
      })
      Text("SuperConnector")
    }.onAppear {
      initialiseState()
    }
    .padding()
  }
  
  func powerButtonPressed() {
    Task {
      await set(path:"netRemote.sys.power",value: poweronoff==0 ? 1 : 0 ) { xml in
        print(xml)
        guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
        if status == "FS_OK" {
          poweronoff = poweronoff==0 ? 1 : 0
        }
      }
    }
  }
  
  
  func initialiseState() {
    Task {
      await get("netRemote.sys.power") { xml in
        print(xml)
        guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
        if status == "FS_OK" {
          guard let powervalue=xml["fsapiResponse"]["value"]["u8"].element?.text as? String else { return }
          poweronoff = Int(powervalue) ?? 0
          Task {
            await get("netRemote.sys.audio.volume") { xml in
              guard let status:String=xml["fsapiResponse"]["status"].element?.text as? String else { return }
              if status == "FS_OK" {
                guard let tmpvolume=xml["fsapiResponse"]["value"]["u8"].element?.text as? String else {
                  return }
                volume = Double(tmpvolume)!
                Task {
                  await set(path:"netRemote.nav.state",value:1) {
                    xml in print(xml)
                    Task {
                      await listGetNext(path:"netRemote.nav.presets") { xml in
                        print(xml)
                      }
                    }
                  }
                 
                }
                
              }
            }
          }
        }
      }
    }
  }
  
  func sessionIdGet(action: @escaping ()-> Void)  {
    if sessionid == "" {
      
      let url="http://"+ipaddress+"/fsapi/CREATE_SESSION?pin=1234"
      
      AF.request(url)
        .responseData { response in
          if let data = response.data {
            let xml = XMLHash.parse(data)
            if let sid = xml["fsapiResponse"]["sessionId"].element?.text {
              sessionid=sid
              action()
            }
          }
        }
      return
    }
    action()
  }
  
  func get(_ path:String, action: @escaping (XMLIndexer)-> Void) async {
    sessionIdGet() {
      let url="http://"+ipaddress+"/fsapi/GET/"+path+"?pin=1234&sid="+sessionid
      
      AF.request(url)
        .responseData { response in
          if let data = response.data {
            let xml = XMLHash.parse(data)
            action(xml)
          }
        }
    }
  }
  
  func set(path:String, value:Int, action: @escaping (XMLIndexer)-> Void) async {
    sessionIdGet() {
      
      let url="http://"+ipaddress+"/fsapi/SET/\(path)?pin=1234&sid=\(sessionid)&value=\(value)"
      
      AF.request(url).responseData { response in
        if let data = response.data {
          let xml = XMLHash.parse(data)
          action(xml)
        }
      }
    }
  }
  
  func listGetNext(path:String, action: @escaping (XMLIndexer)->Void) async {
    sessionIdGet() {
      let url="http://"+ipaddress+"/fsapi/LIST_GET_NEXT/\(path)/-1?pin=1234&sid=\(sessionid)&maxItems=10"
      print(url)
      AF.request(url).responseData { response in
        if let data = response.data {
          let xml = XMLHash.parse(data)
          action(xml)
        }
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
