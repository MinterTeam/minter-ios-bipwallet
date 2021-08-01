//
//  LUAutocompleteTableViewCell.swift
//  LUAutocompleteView
//
//  Created by Laurentiu Ungur on 24/04/2017.
//  Copyright © 2017 Laurentiu Ungur. All rights reserved.
//

import UIKit

public struct TextAutocompleteModel: AutocompleteModel, Comparable {
  public static func < (lhs: TextAutocompleteModel, rhs: TextAutocompleteModel) -> Bool {
    return lhs.description < rhs.description
  }
  
  public var shouldShowCheckmark: Bool
  public var text: String
  
  public var description: String {
    return self.text
  }
}

/// The base class for cells used in `LUAutocompleteView`
open class LUAutocompleteTableViewCell: UITableViewCell {
    // MARK - Public Functions
	
	var searchTerm: String?

    /** Function that is called when cell is configured with given text.
     
    - Parameter text: A string that should be displayed.
     
    - Warning: Must be implemented by each subclass.
    */
    open func set(text: AutocompleteModel, searchText: String? = nil) {
        preconditionFailure("This function must be implemented by each subclass")
    }
}
