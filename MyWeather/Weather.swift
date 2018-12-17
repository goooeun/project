//
//  Weather.swift
//  MyWeather
//
//  Created by goeun on 17/12/2018.
//  Copyright © 2018 goeun. All rights reserved.
//

import Foundation

enum WeatherState: String {
    case sunny, blur, cloudy, lowCloudy, rainy, snowy
}

extension WeatherState {
    func convertKr() -> String {
        switch self {
            case .sunny: return "맑음"
            case .blur: return "흐림"
            case .cloudy: return "구름 많음"
            case .lowCloudy: return "구름 적음"
            case .rainy: return "비"
            case .snowy: return "눈"
        }
    }
}
