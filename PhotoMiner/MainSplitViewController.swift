//
//  MainSplitViewController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 24/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {
	
	static var instance:MainSplitViewController?
	
	var isSidebarCollapsed: Bool {
		get {
			return self.splitViewItems.last?.isCollapsed ?? true
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		MainSplitViewController.instance = self
		
		if let rightItem = splitViewItems.last {
			// Remove the last item and re-add as a sidebar
			removeSplitViewItem(rightItem)
			let sidebarItem = NSSplitViewItem(sidebarWithViewController: rightItem.viewController)
			sidebarItem.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
			sidebarItem.minimumThickness = CGFloat(Configuration.shared.sidepanelMinSize)
			sidebarItem.maximumThickness = CGFloat(Configuration.shared.sidePanelMaxSize)
			sidebarItem.canCollapse = true
			sidebarItem.isCollapsed = true
			addSplitViewItem(sidebarItem)
		}
	}
	
	private var lastCollapsedState = true
	override func splitViewDidResizeSubviews(_ notification: Notification) {
		super.splitViewDidResizeSubviews(notification)
		if lastCollapsedState != isSidebarCollapsed {
			lastCollapsedState = isSidebarCollapsed
			NotificationCenter.default.post(name: isSidebarCollapsed ? TitlebarController.sidebarOffNotification : TitlebarController.sidebarOnNotification, object: self)
		}
	}
	
	override func toggleSidebar(_ sender: Any?) {
		super.toggleSidebar(sender)
		NotificationCenter.default.post(name: isSidebarCollapsed ? TitlebarController.sidebarOffNotification : TitlebarController.sidebarOnNotification, object: self)
	}
	
}
