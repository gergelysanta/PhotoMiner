//
//  PhotoCollectionView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 04/03/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol PhotoCollectionViewDelegate {
	func collectionViewKeyPress(with event: NSEvent)
}

class PhotoCollectionView: NSCollectionView {
	
	var keyDelegate:PhotoCollectionViewDelegate? = nil
	
	override func keyDown(with event: NSEvent) {
		super.keyDown(with: event)
		if let delegate = self.keyDelegate {
			delegate.collectionViewKeyPress(with: event)
		}
	}
	
}
