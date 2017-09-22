//
//  SwiftExampleView.swift
//  ClassyExample
//
//  Created by Peyman Khanjan on 22/09/2017.
//  Copyright © 2017 Jonas Budelmann. All rights reserved.
//

import Foundation
import UIKit

public class SwiftExampleView : UIView {
    public var textColor: UIColor? {
        didSet {
            self.label.textColor = textColor
        }
    }
    
    public let label = UILabel()
    
    @objc
    public init() {
        super.init(frame: .zero)
        
        self.label.text = "Lorem Ipsum"
        self.addSubview(self.label)
        
        self.label.translatesAutoresizingMaskIntoConstraints = false
        
        self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
