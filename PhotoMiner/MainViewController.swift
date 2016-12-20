//
//  MainViewController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
	
	@IBOutlet weak var collectionView: NSCollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}
	
	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
}

