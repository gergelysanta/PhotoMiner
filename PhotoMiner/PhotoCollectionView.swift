//
//  PhotoCollectionView.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 04/03/2017.
//  Copyright © 2017 TriKatz. All rights reserved.
//

import Cocoa

protocol PhotoCollectionViewDelegate {
	func keyPress(_ collectionView: PhotoCollectionView, with event: NSEvent) -> Bool
	func preReloadData(_ collectionView: PhotoCollectionView)
	func postReloadData(_ collectionView: PhotoCollectionView)
}

class PhotoCollectionView: NSCollectionView {
	
	var keyDelegate:PhotoCollectionViewDelegate? = nil
	
	override func keyDown(with event: NSEvent) {
		var eventHandled = false
		if let delegate = self.keyDelegate {
			eventHandled = delegate.keyPress(self, with: event)
		}
		if !eventHandled {
			super.keyDown(with: event)
		}
	}
	
	override func reloadData() {
		if let delegate = self.keyDelegate {
			delegate.preReloadData(self)
			super.reloadData()
			delegate.postReloadData(self)
		}
		else {
			super.reloadData()
		}
	}
	
}
