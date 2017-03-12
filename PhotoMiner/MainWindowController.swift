//
//  MainWindowController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, TitlebarDelegate, ScannerDelegate {
	
	let scanner = Scanner()
	var titlebarController: TitlebarController? = nil
	
    override func windowDidLoad() {
        super.windowDidLoad()
		
		scanner.delegate = self
		self.titlebarController = self.storyboard?.instantiateController(withIdentifier: "TitlebarController") as! TitlebarController?
		
		if let titlebarController = self.titlebarController {
			
			let titleViewFrame = titlebarController.view.frame
			titlebarController.delegate = self
			
			// Hide window title (text only, not the title bar)
			self.window?.titleVisibility = .hidden
			
			// Get default title bar height
			let frame = NSRect(x: 0, y: 0, width: 800, height: 600)
			let contentRect = NSWindow.contentRect(forFrameRect: frame, styleMask: .titled)
			let defaultTitlebarHeight = NSHeight(frame) - NSHeight(contentRect)
			
			// Use NSTitlebarAccessoryViewController for enhancing titlebar
			let dummyTitleBarViewController = NSTitlebarAccessoryViewController()
			dummyTitleBarViewController.view = NSView(frame: NSRect(x: 0.0, y: 0.0, width: 10.0, height: titleViewFrame.size.height - defaultTitlebarHeight))
			
			dummyTitleBarViewController.layoutAttribute = .bottom
			dummyTitleBarViewController.fullScreenMinHeight = 0
			self.window?.addTitlebarAccessoryViewController(dummyTitleBarViewController)
			
			// Add our title view to window title
			if let closeButton = self.window?.standardWindowButton(.closeButton) {
				if let winTitlebarView = closeButton.superview {
					titlebarController.view.frame = NSRect(x: 0, y: 0, width: winTitlebarView.frame.size.width, height: titleViewFrame.size.height)
					
					// Add titleView into superview
					titlebarController.view.translatesAutoresizingMaskIntoConstraints = false
					winTitlebarView.addSubview(titlebarController.view)
					
					let viewsDict = [ "subview": titlebarController.view ]
					NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0.0-[subview]-0.0-|", options: [], metrics: nil, views: viewsDict))
					NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0.0-[subview]-0.0-|", options: [], metrics: nil, views: viewsDict))
				}
			}
			
			self.repositionWindowButton(.closeButton, inView: titlebarController.view)
			self.repositionWindowButton(.miniaturizeButton, inView: titlebarController.view)
			self.repositionWindowButton(.zoomButton, inView: titlebarController.view)
		}
		
		startScan()
    }
	
	//
	// MARK: Private methods
	//
	
	private func repositionWindowButton(_ windowButton: NSWindowButton, inView superView: NSView) {
		if let button = self.window?.standardWindowButton(windowButton) {
			if let originalSuperView = button.superview {
				if originalSuperView != superView {
					// Button must be moved to our titleView in order of correct positioning
					// It will flicker between default and our new position otherwise when resizing window
					button.removeFromSuperview()
					superView.addSubview(button)
					button.translatesAutoresizingMaskIntoConstraints = false
					
					// Layout contraints must be created between the button and it's original superview
					// app will behave strangely otherwise when switched to fullscreen (won't display GUI but will run)
					NSLayoutConstraint(item: button,
					                   attribute: .centerY,
					                   relatedBy: .equal,
					                   toItem: originalSuperView,
					                   attribute: .centerY,
					                   multiplier: 1.0,
					                   constant: 0.0).isActive = true
					NSLayoutConstraint(item: button,
					                   attribute: .left,
					                   relatedBy: .equal,
					                   toItem: originalSuperView,
					                   attribute: .left,
					                   multiplier: 1.0,
					                   constant: button.frame.origin.x).isActive = true
				}
			}
		}
	}
	
	//
	// MARK: Public methods
	//
	
	func startScan() {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			if !scanner.start(pathsToScan: appDelegate.configuration.lookupFolders,
			                  bottomSizeLimit: appDelegate.configuration.ignoreImagesBelowSize)
			{
				// TODO: TODO: Display Warning
			}
			titlebarController?.progressOn(true)
		}
	}
	
	//
	// MARK: TitlebarDelegate methods
	//
	
	func buttonPressed(_ sender: NSButton) {
	}
	
	//
	// MARK: ScannerDelegate methods
	//
	
	func scanSubResult(scanner: Scanner) {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			#if DEBUG
			NSLog("Scan subresult: %d items", scanner.scannedCollection.count)
			#endif
			appDelegate.imageCollection = scanner.scannedCollection
			titlebarController?.setTotalCount(scanner.scannedCollection.count)
			
			if let mainViewController = self.window?.contentViewController as? MainViewController {
				// Reftesh collectionView
				mainViewController.collectionView.reloadData()
			}
		}
	}
	
	func scanFinished(scanner: Scanner) {
		if let appDelegate = NSApp.delegate as? AppDelegate {
			#if DEBUG
			NSLog("Scan result: %d items", scanner.scannedCollection.count)
			#endif
			appDelegate.imageCollection = scanner.scannedCollection
			titlebarController?.setTotalCount(scanner.scannedCollection.count)
			
			if let mainViewController = self.window?.contentViewController as? MainViewController {
				// Reftesh collectionView
				mainViewController.collectionView.reloadData()
			}
		}
		titlebarController?.progressOn(false)
	}
	
}
