//
//  DropDownCellTableViewCell.swift
//  DropDown
//
//  Created by Kevin Hirsch on 28/07/15.
//  Copyright (c) 2015 Kevin Hirsch. All rights reserved.
//

import UIKit

public class DropDownCell: UITableViewCell {
		
	//UI
	@IBOutlet public weak var optionLabel: UILabel!
	
	var selectedBackgroundColor: UIColor?

}

//MARK: - UI

extension DropDownCell {
	
	override public func awakeFromNib() {
		super.awakeFromNib()
		
		backgroundColor = UIColor.clear
	}
	
	override public var isSelected: Bool {
		willSet {
			setSelected(newValue, animated: false)
		}
	}
	
	override public var isHighlighted: Bool {
		willSet {
			setSelected(newValue, animated: false)
		}
	}
	
	override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
		setSelected(highlighted, animated: animated)
	}
	
	override public func setSelected(_ selected: Bool, animated: Bool) {
		let executeSelection: () -> Void = { [unowned self] in
			if let selectedBackgroundColor = self.selectedBackgroundColor {
				if selected {
					self.backgroundColor = selectedBackgroundColor
				} else {
					self.backgroundColor = UIColor.clear
				}
			}
		}
		
		if animated {
			UIView.animate(withDuration: 0.3, animations: {
				executeSelection()
			})
		} else {
			executeSelection()
		}
	}
	
}
