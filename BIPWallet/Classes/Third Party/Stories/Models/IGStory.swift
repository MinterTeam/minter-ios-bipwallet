//
//  IGStory.swift
//
//  Created by Ranjith Kumar on 9/8/17
//  Copyright (c) DrawRect. All rights reserved.
//

import Foundation

//{"id":3,
//  "title":"Test2",
//  "icon":"https://image.minter.network/minter-stories/icon/3",
//  "weight":1,
//  "is_active":true,
//  "expire_date":null,
//  "created_at":"2020-09-28T10:44:06.075043Z",
//  "updated_at":null,
//  "deleted_at":null,
//  "slides"

public class IGStory: Codable {

  init(id: String, icon: String, slides: [IGSnap]) {
    self.internalIdentifier = id
    self.icon = icon
    self._snaps = slides
    self.lastUpdated = 1
  }

    // Note: To retain lastPlayedSnapIndex value for each story making this type as class
  public var snapsCount: Int {
    return snaps.count
  }

  // To hold the json snaps.
  private var _snaps: [IGSnap]

  // To carry forwarding non-deleted snaps.
  public var snaps: [IGSnap] {
    return _snaps.filter{!($0.isDeleted)}
  }

  public var internalIdentifier: String
  public var lastUpdated: Int
  public var weight: Int = 1
  public var icon: String
  var lastPlayedSnapIndex = 0
  var isCompletelyVisible = false
  var isCancelledAbruptly = false

  enum CodingKeys: String, CodingKey {
    //case snapsCount = "snaps_count"
    case _snaps = "slides"
    case weight
    case internalIdentifier = "id"
    case lastUpdated = "updated_at"
    case icon
  }
}

extension IGStory: Equatable {
  public static func == (lhs: IGStory, rhs: IGStory) -> Bool {
    return lhs.internalIdentifier == rhs.internalIdentifier
  }
}
