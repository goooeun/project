//
//  ViewController.swift
//  myWeatherApp
//
//  Created by goeun on 11/06/2018.
//  Copyright © 2018년 basic. All rights reserved.
//

import UIKit
import CoreLocation

class WeatherViewController: UIViewController {
    
    // MARK: - Properties
    private let serviceKey = "OP7tXPTHFPrFYWVKV2tk%2FSD%2BsDUthgeMgrAVjF9f1R5Fjvxpy3PCNxPUH5tQpsLNfsYU9hChJp3SU9vmz7ZuEg%3D%3D"
    
    var locationManager = CLLocationManager()
    var userLocation:CLLocation = CLLocation(latitude:0, longitude:0)
    
    var getLocationOnce = 0
    let nowDateTime = Date()
    let dateFormatter = DateFormatter()
    
    var weatherInfo = [[String:String]]()
    var weatherTemp = [String:String]()
    var weatherKeyTemp:String = ""
    var isDataStart = false
    
    var timeTempArray = [Int]()
    var timeArray = [String]()
    var timeSkyArray = [String]()
    var timePtyArray = [String]()
    var timeEnWeather = [String]()
    
    // 북 : N, 남 : S, 동 : E, 서 : W
    let windLocationArray = ["북", "북북동", "북동", "동북동", "동", "동남동", "남동",
                             "남남동", "남", "남남서", "남서", "서남서", "서", "서북서", "북서", "북북서", "북"]
    var rankArray = [Int]()
    
    var backgroundView: UIView = UIView()
    var indicator = UIActivityIndicatorView()
    
    // MARK: IBOutlet
    @IBOutlet weak var currentLocationLabel: UILabel!
    @IBOutlet weak var timeWeatherCollectionView: UICollectionView!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var weatherKrLabel: UILabel!
    @IBOutlet weak var weatherTempLabel: UILabel!
    @IBOutlet weak var weatherView: UIView!
    @IBOutlet weak var windInfoLabel: UILabel!
    @IBOutlet weak var windWSDInfoLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    
    // MARK: - Methods
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showIndicator()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        timeWeatherCollectionView.backgroundColor = UIColor.clear
    }
    
    // 현재 날씨 정보 리퀘스트
    func getNowWeatherForURL(gridX:Int, gridY:Int) {
        let baseURL:String = "http://newsky2.kma.go.kr/service/SecndSrtpdFrcstInfoService2/ForecastGrib?"
        
        dateFormatter.dateFormat = "yyyyMMdd"
        let baseDate = dateFormatter.string(from: nowDateTime)
        
        dateFormatter.dateFormat = "HHmm"
        var baseTime = dateFormatter.string(from: nowDateTime)
        baseTime = convertTime(nowTime: baseTime)
        
        let paramURL = "ServiceKey=\(serviceKey)&base_date=\(baseDate)&base_time=\(baseTime)&nx=\(gridX)&ny=\(gridY)&numOfRows=10"
        
        print(baseURL+paramURL)
        
        if let fileURL = URL(string: baseURL+paramURL) {
            if let parser = XMLParser(contentsOf: fileURL) {
                parser.delegate = self
                parser.parse()
            }
        }
        
        var skyValue:String = ""
        var ptyValue:String = ""
        
        for i in 0 ..< weatherInfo.count {
            guard let weatherCategory = weatherInfo[i]["category"] else { return }
            guard let weatherValue = weatherInfo[i]["obsrValue"] else { return }
            
            switch weatherCategory {
                case "T1H":
                    weatherTempLabel.text = "\(weatherValue)℃"
                case "SKY":
                    skyValue = weatherValue
                case "PTY":
                    ptyValue = weatherValue
                case "REH":
                    humidityLabel.text = "\(weatherValue)%"
                case "VEC":
                    guard let windLocation: Double = Double(weatherValue) else { return }
                    let convertWindLocation = floor((windLocation + 22.5 * 0.5) / 22.5)
                    windInfoLabel.text = "\(windLocationArray[Int(convertWindLocation)])"
                case "WSD":
                    guard let wsdValue: Double = Double(weatherValue) else { return }
                    let convertWsdValue = round(wsdValue)
                    windWSDInfoLabel.text = "\(Int(convertWsdValue))m/s"
                default: break
            }
        }
        
        var weatherState: WeatherState = .sunny
        
        if ptyValue == "0" {
            switch skyValue {
                case "1": weatherState = .sunny
                case "2": weatherState = .lowCloudy
                case "3": weatherState = .cloudy
                case "4": weatherState = .blur
                default: break
            }
        } else {
            switch ptyValue {
                case "1": weatherState = .rainy
                case "3": weatherState = .snowy
                default: break;
            }
        }
        
        let weatherImageName = weatherState.rawValue
        weatherImageView.image = UIImage(named: weatherImageName)
        
        weatherKrLabel.text = weatherState.convertKr()
        
        weatherInfo.removeAll()
        weatherTemp.removeAll()
        weatherKeyTemp = ""
        isDataStart = false
        
        weatherView.setNeedsLayout()
        
        if weatherState == .sunny {
            UIView.animate(withDuration: 5.0, animations: ({
                self.weatherImageView.transform = CGAffineTransform(rotationAngle: 360)
            }))
        } else {
            UIView.animate(withDuration: 6.0, delay: 2.0, options: [.autoreverse, .repeat], animations: {
                self.weatherImageView.frame.origin.y = -5
            })
        }
    }
    
    func getTimeWeatherForURL(gridX:Int, gridY:Int) {
        let baseURL:String = "http://newsky2.kma.go.kr/service/SecndSrtpdFrcstInfoService2/ForecastSpaceData?"
        
        dateFormatter.dateFormat = "yyyyMMdd"
        let baseDate = dateFormatter.string(from: nowDateTime)
        
        dateFormatter.dateFormat = "HHmm"
        var baseTime = "\(dateFormatter.string(from: nowDateTime))"
        
        baseTime = self.convertBaseTime(nowTime: baseTime)
        
        let paramURL = "ServiceKey=\(serviceKey)&base_date=\(baseDate)&base_time=\(baseTime)&nx=\(gridX)&ny=\(gridY)&numOfRows=200"
        
        print(baseURL+paramURL)
        
        if let fileURL = URL(string: baseURL+paramURL) {
            if let parser = XMLParser(contentsOf: fileURL) {
                parser.delegate = self
                parser.parse()
            }
        }
        
        for i in 0 ..< weatherInfo.count {
            guard let weatherCategory = weatherInfo[i]["category"] else { return }
            guard let weatherValue = weatherInfo[i]["fcstValue"] else { return }
            
            if weatherCategory == "T3H" {
                guard let weatherTime = weatherInfo[i]["fcstTime"] else { return }
                timeArray.append(weatherTime)
                
                if let temperature: Int = Int(weatherValue) {
                    timeTempArray.append(temperature)
                }
            }
            if weatherCategory == "SKY" {
                timeSkyArray.append(weatherValue)
            }
            if weatherCategory == "PTY" {
                timePtyArray.append(weatherValue)
            }
        }
        
        for i in 0 ..< timePtyArray.count {
            var weatherState: WeatherState = .sunny
            if timePtyArray[i] == "0" {
                switch timeSkyArray[i] {
                    case "1": weatherState = .sunny
                    case "2": weatherState = .lowCloudy
                    case "3": weatherState = .cloudy
                    case "4": weatherState = .blur
                    default: break
                }
            } else {
                switch timePtyArray[i] {
                    case "1": weatherState = .rainy
                    case "3": weatherState = .snowy
                    default: break
                }
            }
            
            let weatherImageName = weatherState.rawValue
            timeEnWeather.append(weatherImageName)
        }
        
        rankArray = [Int](repeatElement(1, count: timeTempArray.count))
        
        for i in 0 ..< timeTempArray.count {
            for j in 0 ..< timeTempArray.count {
                if i != j {
                    if timeTempArray[i] < timeTempArray[j]{
                        rankArray[i] += 1
                    }
                }
            }
        }
        
        weatherInfo.removeAll()
        weatherTemp.removeAll()
        weatherKeyTemp = ""
        isDataStart = false
        
        timeWeatherCollectionView.reloadData()
        
    }
    
    // 동네예보 baseTime 기준 시간
    // 02:00, 05:00, 08:00, 11:00, 14:00, 17:00, 20:00, 23:00 (1일8회)
    // 실제 적용가능 시간은 10분 후
    // ex ) nowTime = 1528 -> 1500
    // ex ) nowTime = 1508 -> 1400
    func convertBaseTime(nowTime:String) -> String {
        var returnTime: String = ""
        let nowHour = Int(nowTime[..<nowTime.index(nowTime.startIndex, offsetBy:2)])!
        let nowMinute = Int(nowTime[nowTime.index(nowTime.startIndex, offsetBy:2)...])!
        
        switch nowHour {
        case 2..<5:
            returnTime = "0200"
            if nowHour == 2 {
                if nowMinute <= 10 {
                    returnTime = "2300"
                }
            }
        case 5..<8:
            returnTime = "0500"
            if nowHour == 5 {
                if nowMinute <= 10 {
                    returnTime = "0200"
                }
            }
        case 8..<11:
            returnTime = "0800"
            if nowHour == 8 {
                if nowMinute <= 10 {
                    returnTime = "0500"
                }
            }
        case 11..<14:
            returnTime = "1100"
            if nowHour == 11 {
                if nowMinute <= 10 {
                    returnTime = "0800"
                }
            }
        case 14..<17:
            returnTime = "1400"
            if nowHour == 14 {
                if nowMinute <= 10 {
                    returnTime = "1100"
                }
            }
        case 17..<20:
            returnTime = "1700"
            if nowHour == 17 {
                if nowMinute <= 10 {
                    returnTime = "1400"
                }
            }
        case 20..<23:
            returnTime = "2000"
            if nowHour == 20 {
                if nowMinute <= 10 {
                    returnTime = "1700"
                }
            }
        default:
            returnTime = "2300"
        }
        
        return returnTime
    }
    
    func convertTime(nowTime:String) -> String {
        var returnTime: String = ""
        let nowHour = Int(nowTime[..<nowTime.index(nowTime.startIndex, offsetBy:2)])!
        let nowMinute = Int(nowTime[nowTime.index(nowTime.startIndex, offsetBy:2)...])!
        
        if nowMinute < 40 {
            if nowHour < 10 {
                returnTime = "0\(nowHour-1)00"
            } else {
                returnTime = "\(nowHour-1)00"
            }
        } else {
            returnTime = "\(nowHour)00"
        }
        
        return returnTime
    }
}

// 현재 위치의 위도 경도를 구하고 동네예보를 위한 x,y와 한글 주소로 변환
extension WeatherViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coor = manager.location?.coordinate {
            print("latitude,longitude : \(coor.latitude),\(coor.longitude)")
            
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            
            let myLatitude = coor.latitude
            let myLongitude = coor.longitude
            
            userLocation = CLLocation(latitude:myLatitude, longitude:myLongitude)
            self.convertToAddressWith(coordinate: userLocation)
            
            let myareaXY = self.getMyAreaXY(latitude:myLatitude, longitude:myLongitude)
            let myGridX = Int(myareaXY["x"]!)
            let myGridY = Int(myareaXY["y"]!)
            
            self.getNowWeatherForURL(gridX: myGridX, gridY: myGridY)
            self.getTimeWeatherForURL(gridX: myGridX, gridY: myGridY)
        }
    }
    
    // 위도 경도 값을 한글 주소로 변경
    func convertToAddressWith(coordinate: CLLocation) {
        let geoCoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr")
        geoCoder.reverseGeocodeLocation(userLocation, preferredLocale: locale, completionHandler: {(placemarks, error) in
            if let address:[CLPlacemark] = placemarks {
                guard let lastAddress = address.last else { return }
                guard let locality:String = lastAddress.locality else { return }
                
                if let subAdministrativeArea:String = lastAddress.subAdministrativeArea {
                    self.currentLocationLabel.text = "\(locality), \(subAdministrativeArea)"
                } else {
                    // 도로명 주소인 경우
                    guard let thoroughfare = lastAddress.thoroughfare else { return }
                    self.currentLocationLabel.text = "\(locality), \(thoroughfare)"
                }
            }
        })
    }
    
    // 현재 위치의 위도 경도로 동네예보조회에서 사용할 그리드 x,y좌표 구하기
    func getMyAreaXY(latitude:Double, longitude:Double) -> [String:Double] {
        let RE = 6371.00877; // 지구 반경(km)
        let GRID = 5.0; // 격자 간격(km)
        let SLAT1 = 30.0; // 투영 위도1(degree)
        let SLAT2 = 60.0; // 투영 위도2(degree)
        let OLON = 126.0; // 기준점 경도(degree)
        let OLAT = 38.0; // 기준점 위도(degree)
        let XO = 43; // 기준점 X좌표(GRID)
        let YO = 136; // 기1준점 Y좌표(GRID)
        
        let DEGRAD = Double.pi / 180.0
        
        let re = RE / GRID
        let slat1 = SLAT1 * DEGRAD
        let slat2 = SLAT2 * DEGRAD
        let olon = OLON * DEGRAD
        let olat = OLAT * DEGRAD
        
        var ra:Double = 0.0
        var theta:Double = 0.0
        
        var sn = tan(Double.pi * 0.25 + slat2 * 0.5) / tan(Double.pi * 0.25 + slat1 * 0.5)
        sn = log(cos(slat1) / cos(slat2)) / log(sn)
        
        var sf = tan(Double.pi * 0.25 + slat1 * 0.5)
        sf = pow(sf, sn) * cos(slat1) / sn
        
        var ro = tan(Double.pi * 0.25 + olat * 0.5)
        ro = re * sf / pow(ro, sn)
        
        var rs = [String:Double]()
        
        ra = tan(Double.pi * 0.25 + (latitude) * DEGRAD * 0.5)
        ra = re * sf / pow(ra, sn)
        
        theta = longitude * DEGRAD - olon
        
        if (theta > Double.pi) {
            theta -= 2.0 * Double.pi
        }
        
        if (theta < -Double.pi) {
            theta += 2.0 * Double.pi
        }
        
        theta *= sn;
        rs["x"] = floor(ra * sin(theta) + Double(XO) + 0.5)
        rs["y"] = floor(ro - ra * cos(theta) + Double(YO) + 0.5)
        
        return rs
    }
}

extension WeatherViewController: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "item" {isDataStart = true}
        weatherKeyTemp = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isDataStart == true && weatherKeyTemp != "item" && weatherKeyTemp != "" {
            if string.contains("\n") != true {
                weatherTemp[weatherKeyTemp] = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        weatherKeyTemp = ""
        if elementName == "item" && isDataStart == true {
            weatherInfo += [weatherTemp]
            isDataStart = false
        }
    }
}

extension WeatherViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "weatherCell", for: indexPath) as? WeatherCollectionViewCell else {
            let cell = WeatherCollectionViewCell()
            return cell
        }
        
        cell.weatherTempLabel.text = "\(timeTempArray[indexPath.row])"
        
        let timeText = timeArray[indexPath.row]
        cell.timeLabel.text = timeText[..<timeText.index(timeText.startIndex, offsetBy:2)] + "시"
        
        let weatherImageName = "\(timeEnWeather[indexPath.row])"
        cell.weatherImageView.image = UIImage(named:weatherImageName)
        
        cell.timeWeatherImageTopMargin.constant = CGFloat(50 + (rankArray[indexPath.row]*5))
        
        self.hideIndicator()
        
        return cell
    }
}

// custom indicator
extension WeatherViewController {
    func showIndicator() {
        let viewWidth: CGFloat = self.view.frame.width
        let viewHeight: CGFloat = self.view.frame.height
        
        backgroundView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        
        let backgroundImageView = UIImageView()
        backgroundImageView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        backgroundImageView.image = UIImage(named: "background")
        
        backgroundView.addSubview(backgroundImageView)
        
        indicator.style = .whiteLarge
        indicator.center = CGPoint(x: self.view.center.x, y: self.view.center.y)
        
        backgroundView.addSubview(indicator)
        self.view.addSubview(backgroundView)
        
        indicator.startAnimating()
    }
    
    func hideIndicator() {
        self.indicator.removeFromSuperview()
        self.backgroundView.removeFromSuperview()
    }
}
