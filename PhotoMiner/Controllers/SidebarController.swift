//
//  SidebarController.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 25/01/2018.
//  Copyright © 2018 TriKatz. All rights reserved.
//

import Cocoa
import MapKit

class SidebarController: NSViewController {

    static var instance:SidebarController?

    @objc dynamic var imagePath:String = ""

    private var exifKeys = [String]()
    var exifData = [String:AnyObject]() {
        didSet {
            exifKeys = Array(exifData.keys).sorted()
            refreshExifTable()
        }
    }

    private var gpsMark: MKAnnotation?
    private var defaultRegion: MKCoordinateRegion?

    @IBOutlet private var mapView: MKMapView!
    @IBOutlet private var exifTableView: NSTableView!
    @IBOutlet private var exifTableHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        SidebarController.instance = self
        exifTableHeightConstraint.constant = 0.0
        defaultRegion = mapView.region
    }

    func exifValueToString(_ value: AnyObject) -> String? {
        func arrayToString(_ array: [AnyObject]) -> String {
            var string = "[ "
            for value in array {
                if string.count > 2 {
                    string += ", "
                }
                if let strValue = value as? String {
                    string += strValue
                }
                else if let intValue = value as? Int {
                    string += String(intValue)
                }
                else if let doubleValue = value as? Double {
                    string += String(doubleValue)
                }
                else {
                    string += "<unknown data>"
                }
            }
            return string + " ]"
        }

        if let strValue = value as? String {
            return strValue
        }
        else if let intValue = value as? Int {
            return String(intValue)
        }
        else if let doubleValue = value as? Double {
            return String(doubleValue)
        }
        else if let arrayValue = value as? [AnyObject] {
            return arrayToString(arrayValue)
        }

        return nil
    }

    func setLocation(latitude: Double, longitude: Double) {
        if let mark = gpsMark {
            mapView.removeAnnotation(mark)
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let regionRadius: CLLocationDistance = 1000		// in meters

        // Mark location on map
        gpsMark = MapPin(pointTo: coordinate)
        mapView.addAnnotation(gpsMark!)

        // Zoom in to 1000m area
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)

        mapView.needsDisplay = true
    }

    func clearLocation() {
        // Remove mark
        if let mark = gpsMark {
            mapView.removeAnnotation(mark)
        }
        // Set the default region
        if let region = defaultRegion {
            mapView.setRegion(region, animated: true)
        }
        self.view.layout()

        mapView.needsDisplay = true
    }

    private func refreshExifTable() {
        exifTableView.reloadData()

        exifTableHeightConstraint.constant = (exifTableView.rowHeight + exifTableView.intercellSpacing.height) * CGFloat(exifTableView.numberOfRows)

        for (columnIndex, column) in exifTableView.tableColumns.enumerated() {
            var maxWidth:CGFloat = 0
            for rowIndex in 0..<exifTableView.numberOfRows {
                if let cellView = exifTableView.view(atColumn: columnIndex, row: rowIndex, makeIfNecessary: true) as? NSTableCellView {
                    let width = cellView.textField?.sizeThatFits(NSZeroSize).width ?? 0
                    if width > maxWidth {
                        maxWidth = width
                    }
                }
            }
            column.width = maxWidth
        }
    }

}

extension SidebarController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return exifKeys.count
    }

}

extension SidebarController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        if row >= exifData.keys.count { return nil }

        let isKeyColumn = tableColumn.identifier == NSUserInterfaceItemIdentifier("key")
        let cellIdentifier = isKeyColumn ? NSUserInterfaceItemIdentifier("ExifKeyCell") : NSUserInterfaceItemIdentifier("ExifValueCell")
        let cellView = (tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView) ?? NSTableCellView()

        if isKeyColumn {
            cellView.textField?.stringValue = "" + exifKeys[row] + ":"
        }
        else {
            if let value = exifData[exifKeys[row]] {
                cellView.textField?.stringValue = exifValueToString(value) ?? ""
            }
            else {
                cellView.textField?.stringValue = ""
            }
        }

        return cellView
    }

}
