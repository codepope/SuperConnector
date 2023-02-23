//
//  SuperDiscovery.swift
//  SuperConnector
//
//  Created by Dj Walker-Morgan on 23/02/2023.
//

import Foundation

import SSDPClient

class ServiceDiscovery: SSDPDiscoveryDelegate {
    let client = SSDPDiscovery()

    var address=""
  
    init() {
        self.client.delegate = self
        self.client.discoverService()
    }
  
  func ssdpDiscovery(_: SSDPDiscovery, didDiscoverService: SSDPService) {
    if didDiscoverService.searchTarget=="urn:schemas-frontier-silicon-com:undok:fsapi:1" {
      address=didDiscoverService.host
      print("Found ",didDiscoverService.host)
      client.stop()
    }
  }
}
