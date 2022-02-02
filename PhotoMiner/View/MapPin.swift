//
//  MapPin.swift
//  PhotoMiner
//
//  Created by Gergely Sánta on 24/02/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import Cocoa
import MapKit

class MapPin: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D

    init(pointTo: CLLocationCoordinate2D) {
        coordinate = pointTo
        super.init()
    }

}
