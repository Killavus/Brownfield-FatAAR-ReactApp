//
//  EventPipeProxy.swift
//  RNLib
//
//  Created by Marcin Grzywaczewski on 11/03/2026.
//

import Foundation
import NitroEventPipe

public class EventPipeProxy {
  public class var delegate: EventPipeProxyProtocol? {
    set {
      EventPipeConfig.delegate = EventPipeProtocolWrapper(delegate: newValue)
    }
    get {
      if let wrapper = EventPipeConfig.delegate as? EventPipeProtocolWrapper {
        return wrapper.delegate
      }
      return nil
    }
  }
}

public protocol EventPipeProxyProtocol {
  var onAccommodationChange: ((AccommodationMap) -> Void)? { get set }

  func accommodationMapRequested() -> Bool
  func accommodationSelected(hotelId: String)
  func refreshRequested()
}

private class EventPipeProtocolWrapper: EventPipeProtocol {
  fileprivate var onAccommodationChange: ((AccommodationMap) -> Void)?
  
  var delegate: EventPipeProxyProtocol?
  
  init(delegate: EventPipeProxyProtocol? = nil) {
    self.delegate = delegate
    
    self.delegate?.onAccommodationChange = { [weak self] (accomodationMap) in
      self?.onAccommodationChange?(accomodationMap)
    }
  }
  
  func accommodationMapRequested() -> Bool {
    delegate?.accommodationMapRequested() ?? false
  }
  
  func accommodationSelected(hotelId: String) {
    delegate?.accommodationSelected(hotelId: hotelId)
  }
  
  func refreshRequested() {
    delegate?.refreshRequested()
  }
}
