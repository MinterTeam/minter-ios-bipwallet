//
//  IGSnap.swift
//
//  Created by Ranjith Kumar on 9/28/17
//  Copyright (c) DrawRect. All rights reserved.
//

import Foundation

public enum MimeType: String {
  case image
  case video
  case unknown
}

//{"id":1,"story_id":1,"weight":0,"title":"test","file":"https://image.minter.network/minter-stories/2/slide/1","link":"https://minter.network","created_at":"2020-09-28T10:46:30.969621Z","updated_at":null,"deleted_at":null}

public class IGSnap: Codable {
  public var storyId: Int?
  public var weight: Int = 1
  public var title: String
  public var file: String
  public var internalIdentifier: Int
  public var mimeType: String = MimeType.image.rawValue
  public var lastUpdated: String? = ""
  public var url: String

  init(id: Int, storyId: Int, title: String, file: String, url: String) {
    self.internalIdentifier = id
    self.storyId = storyId
    self.title = title
    self.file = file
    self.url = url
    self.mimeType = MimeType.image.rawValue
    self.lastUpdated = ""
  }

  // Store the deleted snaps id in NSUserDefaults, so that when app get relaunch deleted snaps will not display.
  public var isDeleted: Bool {
    set {
      UserDefaults.standard.set(newValue, forKey: "\(internalIdentifier)")
    }
    get {
      return UserDefaults.standard.value(forKey: "\(internalIdentifier)") != nil
    }
  }

  public var kind: MimeType {
    switch mimeType {
      case MimeType.image.rawValue:
        return MimeType.image
      case MimeType.video.rawValue:
        return MimeType.video
      default:
        return MimeType.unknown
    }
  }

  enum CodingKeys: String, CodingKey {
    case internalIdentifier = "id"
    case storyId = "story_id"
//    case mimeType = "mime_type"
    case lastUpdated = "last_updated"
    case url = "link"
    case file
    case weight
    case title
  }
}
