//
//  UIKit+UIAplication.swift
//  BandSyncApp
//
//  Created by Oleh on 23.05.2025.
//

import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
