//
//  FilesData.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 21/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class FilesData: NSObject {
	
	private var filesArray = [String: String]()
	
	func setFilesArray(_ newArray:[String: String]) {
		filesArray = newArray
		// TODO: Send notification about data change, so the collectionView can update it's content
	}
	
}
