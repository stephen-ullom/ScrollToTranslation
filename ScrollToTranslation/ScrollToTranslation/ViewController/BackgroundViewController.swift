//
//  BackgroundViewController.swift
//  ScrollToTranslation
//
//  Created by Gaétan Zanella on 08/08/2018.
//  Copyright © 2018 Gaétan Zanella. All rights reserved.
//

 import MapKit
import UIKit

class BackgroundViewController: UIViewController {
  override func loadView() {
    view = MKMapView()
  }

//  override func viewDidLoad() {
//    view.backgroundColor = .systemGray6
//
//    let label = UILabel()
//    label.text = "Hello World"
//    view.addSubview(label)
//
//    label.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//      label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//    ])
//  }
}
