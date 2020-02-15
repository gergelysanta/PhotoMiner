//
//  MainWindowController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 07/12/2016.
//  Copyright © 2016 TriKatz. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
	
	let scanner = Scanner()
	var titlebarController: TitlebarController? = nil
	
	var mainViewController:MainViewController? {
		get {
			return MainViewController.instance
		}
	}
	
	var hasContent:Bool {
		get {
			return (mainViewController?.collectionView.numberOfSections ?? 0) > 0
		}
	}
	
	var isDragAndDropVisible:Bool {
		get {
			return mainViewController?.isDropViewVisible ?? false
		}
		set {
			mainViewController?.isDropViewVisible = newValue
		}
	}
	
    override func windowDidLoad() {
        super.windowDidLoad()
		
		// Set initial size of the window
		if let window = self.window {
			window.setFrame(NSRect(origin: window.frame.origin, size: CGSize(width: 1020, height: 700)), display: true)
		}

		scanner.delegate = self
		self.titlebarController = self.storyboard?.instantiateController(withIdentifier: "TitlebarController") as! TitlebarController?
		guard let titlebarController = self.titlebarController else { return }
		
		let titleViewFrame = titlebarController.view.frame
		titlebarController.delegate = self
		
		// Hide window title (text only, not the title bar)
		self.window?.titleVisibility = .hidden
		
		// Get default title bar height
		let frame = NSRect(x: 0, y: 0, width: 800, height: 600)
		let contentRect = NSWindow.contentRect(forFrameRect: frame, styleMask: NSWindow.StyleMask.titled)
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
	
	//
	// MARK: - Private methods
	//
	
	private func repositionWindowButton(_ windowButton: NSWindow.ButtonType, inView superView: NSView) {
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
	// MARK: - Public methods
	//
	
	func refreshPhotos() {
		// Reftesh collectionView
		mainViewController?.collectionView.reloadData()
		// Refresh window title
		titlebarController?.setTotalCount(AppData.shared.imageCollection.count)
	}
	
}

extension MainWindowController: NSWindowDelegate {
	
	func windowShouldClose(_ sender: NSWindow) -> Bool {
		if let appDelegate = NSApp.delegate as? AppDelegate,
			let fileUrl = AppData.shared.openedFileUrl,
			AppData.shared.loadedImageSetChanged
		{
			appDelegate.confirmAction(NSLocalizedString("Your loaded scan changed. Do you want to save it before terminating application?", comment: "Confirmation for saving before termination"),
									  forWindow: appDelegate.mainWindowController?.window,
									  action: { (response) in
										if response {
											appDelegate.saveImageDatabase(fileUrl, onError: {})
											NSApp.terminate(self)
										}
			})
			return false
		}
		return true
	}
	
}

// MARK: - TitlebarDelegate methods
extension MainWindowController: TitlebarDelegate {

	func titlebar(_ controller: TitlebarController, startScanForPath scanPath: String?) {
		let dialog = NSOpenPanel()
		
		dialog.title = "Select a directory to scan"
		dialog.showsHiddenFiles        = false
		dialog.canChooseDirectories    = true
		dialog.canChooseFiles          = false
		dialog.allowsMultipleSelection = true

		if let path = scanPath {
			dialog.directoryURL        = URL(fileURLWithPath: path)
		}
		
		let successBlock: (NSApplication.ModalResponse) -> Void = { response in
			if response == .OK {
				var directoryList = [String]()
				for url in dialog.urls {
					directoryList.append(url.path)
				}
				AppData.shared.setLookupDirectories(directoryList)
				
				// Start scan without confirmation
				(NSApp.delegate as? AppDelegate)?.startScan(withConfirmation: false)
			}
		}
		
		if let window = self.window {
			dialog.beginSheetModal(for: window, completionHandler: successBlock)
		}
		else {
			dialog.begin(completionHandler: successBlock)
		}
	}
	
	func titlebar(_ controller: TitlebarController, cancelButtonPressed sender: NSButton) {
		self.scanner.stop()
	}
	
	func titlebarSidebarToggled(_ controller: TitlebarController) {
		MainSplitViewController.instance?.toggleSidebar(self)
	}
	
}

// MARK: - ScannerDelegate methods
extension MainWindowController: ScannerDelegate {
	
	func scanSubResult(scanner: Scanner) {
		#if DEBUG
		NSLog("Scan subresult: %d items", scanner.scannedCollection.count)
		#endif
		AppData.shared.imageCollection = scanner.scannedCollection
		
		refreshPhotos()
	}
	
	func scanFinished(scanner: Scanner) {
		#if DEBUG
		NSLog("Scan result: %d items", scanner.scannedCollection.count)
		#endif
		AppData.shared.imageCollection = scanner.scannedCollection
		
		refreshPhotos()
		
		titlebarController?.progressOn(false)
	}
	
}
