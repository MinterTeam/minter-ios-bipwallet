//
//  StoriesService.swift
//  BIPWallet
//
//  Created by Alexey Sidorov on 21.10.2020.
//  Copyright © 2020 Alexey Sidorov. All rights reserved.
//

import Foundation
import RxSwift

protocol StoriesService {
  func stories() -> Observable<[IGStory]>
  func storyShowed(id: Int)
  func updateStories()
  func hasSeen(storyId: Int) -> Bool
}
