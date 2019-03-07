//
//  Sticker.swift
//  GIFME2
//
//  Created by Tyler Pharand on 2019-02-27.
//  Copyright © 2019 Tyler Pharand. All rights reserved.
//

import Foundation
import UIKit

//struct Sticker {
//    let stickerPreview: UIImage
//    let stickerIdentifier: String
//    let stickerData: UIImage
//}


class Sticker: NSObject, NSCoding {
    let stickerUrl: String
    let stickerData: Data
    
    init(stickerUrl: String, stickerData: Data) {
        self.stickerUrl = stickerUrl
        self.stickerData = stickerData
    }
    required init(coder decoder: NSCoder) {
        self.stickerUrl = decoder.decodeObject(forKey: "stickerUrl") as? String ?? ""
        self.stickerData = decoder.decodeObject(forKey: "stickerData") as? Data ?? Data()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(stickerUrl, forKey: "stickerUrl")
        coder.encode(stickerData, forKey: "stickerData")
    }
}
