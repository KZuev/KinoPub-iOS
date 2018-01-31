//
//  Device.swift
//
//  Created by hintoz on 26.05.17
//  Copyright (c) . All rights reserved.
//

import Foundation
import ObjectMapper

public class Device: Mappable {

  // MARK: Declaration for string constants to be used to decode and also serialize.
  private struct SerializationKeys {
    static let updated = "updated"
    static let hardware = "hardware"
    static let lastSeen = "last_seen"
    static let id = "id"
    static let created = "created"
    static let title = "title"
    static let software = "software"
  }

  // MARK: Properties
  public var updated: Int?
  public var hardware: String?
  public var lastSeen: Int?
  public var id: Int?
  public var created: Int?
  public var title: String?
  public var software: String?

  // MARK: ObjectMapper Initializers
  /// Map a JSON object to this class using ObjectMapper.
  ///
  /// - parameter map: A mapping from ObjectMapper.
  public required init?(map: Map) {

  }

  /// Map a JSON object to this class using ObjectMapper.
  ///
  /// - parameter map: A mapping from ObjectMapper.
  public func mapping(map: Map) {
    updated <- map[SerializationKeys.updated]
    hardware <- map[SerializationKeys.hardware]
    lastSeen <- map[SerializationKeys.lastSeen]
    id <- map[SerializationKeys.id]
    created <- map[SerializationKeys.created]
    title <- map[SerializationKeys.title]
    software <- map[SerializationKeys.software]
  }
}