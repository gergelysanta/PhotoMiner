//
//  PhotoCollectionView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 04/03/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol PhotoCollectionViewDelegate {
	func collectionViewKeyPress(with event: NSEvent) -> Bool
}

class PhotoCollectionView: NSCollectionView {
	
	var keyDelegate:PhotoCollectionViewDelegate? = nil
	
	override func keyDown(with event: NSEvent) {
		var eventHandled = false
		if let delegate = self.keyDelegate {
			eventHandled = delegate.collectionViewKeyPress(with: event)
		}
		if !eventHandled {
			super.keyDown(with: event)
		}
	}
	
}
