//
//  WeatherCollectionViewCell.swift
//  MyWeather
//
//  Created by goeun on 13/06/2018.
//  Copyright © 2018 goeun. All rights reserved.
//

import UIKit

import UIKit

class WeatherCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var weatherTempLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeWeatherImageTopMargin: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
