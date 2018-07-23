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
	func drag(_ collectionView: PhotoCollectionView, session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation)
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
		keyDelegate?.preReloadData(self)
		super.reloadData()
		keyDelegate?.postReloadData(self)
	}
	
	override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
		switch(context) {
		case .outsideApplication:
			return [ .copy, .link, .generic, .delete, .move ]
		case .withinApplication:
			return NSDragOperation(rawValue: 0)
		}
	}
	
	override func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
		super.draggingSession(session, endedAt: screenPoint, operation: operation)
		keyDelegate?.drag(self, session: session, endedAt: screenPoint, operation: operation)
	}
	
}
