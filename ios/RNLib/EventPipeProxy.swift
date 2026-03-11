//
//  EventPipeProxy.swift
//  RNLib
//
//  Created by Marcin Grzywaczewski on 11/03/2026.
//

import Foundation
internal import NitroEventPipe

// Nitro types are using C++ structs as underlying implementation, meaning directly using them would require a host app to be able to compile C++ and interop with Swift. Creating structs with the same fields as these types allows us to interop with Nitro Module _without_ needing to enable Swift/C++ interop.

public struct RNAccommodation {
  public var name: String
  public var lat: Double
  public var longit: Double
  public var hotelId: String

  public init(name: String, lat: Double, longit: Double, hotelId: String) {
    self.name = name
    self.lat = lat
    self.longit = longit
    self.hotelId = hotelId
  }
}

public struct RNAccommodationMap {
  public var results: [RNAccommodation]

  public init(results: [RNAccommodation]) {
    self.results = results
  }
}

// MARK: - Conversions (internal only)

extension RNAccommodation {
  init(from cxx: Accommodation) {
    self.init(name: cxx.name, lat: cxx.lat, longit: cxx.longit, hotelId: cxx.hotelId)
  }
}

extension RNAccommodationMap {
  init(from cxx: AccommodationMap) {
    self.init(results: cxx.results.map { RNAccommodation(from: $0) })
  }

  func toCxx() -> AccommodationMap {
    AccommodationMap(results: results.map { $0.toCxx() })
  }
}

extension RNAccommodation {
  func toCxx() -> Accommodation {
    Accommodation(name: name, lat: lat, longit: longit, hotelId: hotelId)
  }
}

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
  var onAccommodationChange: ((RNAccommodationMap) -> Void)? { get set }

  func accommodationMapRequested() -> Bool
  func accommodationSelected(hotelId: String)
  func refreshRequested()
}

private class EventPipeProtocolWrapper: EventPipeProtocol {
  fileprivate var onAccommodationChange: ((AccommodationMap) -> Void)?

  var delegate: EventPipeProxyProtocol?

  init(delegate: EventPipeProxyProtocol? = nil) {
    self.delegate = delegate

    self.delegate?.onAccommodationChange = { [weak self] (rnAccommodationMap) in
      self?.onAccommodationChange?(rnAccommodationMap.toCxx())
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
