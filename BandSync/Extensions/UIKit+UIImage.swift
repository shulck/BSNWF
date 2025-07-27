//
//  UIKit+UIImage.swift
//  BandSync
//
//  Created by Oleh on 24.05.2025.
//

import UIKit

extension UIImage: @retroactive Identifiable {
    public var id: String { UUID().uuidString }
}
