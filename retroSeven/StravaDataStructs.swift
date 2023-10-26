//
//  StravaDataStructs.swift
//  retroSeven
//
//  Created by Conor Sleith on 10/23/23.
//

import Foundation

let MilesToMetersFactor = 0.000621371

struct Athlete: Decodable {
    let id: Int
    let resourceState: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceState = "resource_state"
    }
}

struct Map: Decodable {
    let id: String
    let resourceState: Int
    let summaryPlotline: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case resourceState = "resource_state"
        case summaryPlotline = "summary_plotline"
    }
}

struct StravaActivity: Decodable {
//    let achievementCount: Int
//    let athleteCount: Int
//    let averageCadence: Double
//    let averageHeartrate: Double
//    let averageSpeed: Double
//    let averageTemp: Int
//    let commentCount: Int
//    let commute: Bool
//    let displayHideHeartrateOption: Bool
    let distance: Double
//    let elapsedTime: Int
//    let elevHigh: Double
//    let elevLow: Double
//    let endLatlng: [Double]
//    let externalId: String
//    let flagged: Bool
//    let fromAcceptedTag: Bool
//    let gearId: String
//    let hasHeartrate: Bool
//    let hasKudoed: Bool
//    let heartrateOptOut: Bool
//    let id: Int
//    let kudosCount: Int
//    let locationCity: String?
//    let locationCountry: String?
//    let locationState: String?
//    let manual: Bool
//    let maxHeartrate: Double
//    let maxSpeed: Double
//    let movingTime: Int
//    let name: String
//    let photoCount: Int
//    let prCount: Int
//    let isPrivate: Bool
//    let resourceState: Int
    let sportType: String
    let startDate: String
    let startDateLocal: String
//    let startLatlng: [Double]
//    let sufferScore: Double
//    let timezone: String
//    let totalElevationGain: Double
//    let totalPhotoCount: Int
//    let isTrainer: Bool
//    let type: String
//    let uploadId: Int
//    let uploadIdStr: String
//    let utcOffset: Double
//    let visibility: String
//    let workoutType: Int
    
    enum CodingKeys: String, CodingKey {
//        case achievementCount = "achievement_count"
//        case athleteCount = "athlete_count"
//        case averageCadence = "average_cadence"
//        case averageHeartrate = "average_heartrate"
//        case averageSpeed = "average_speed"
//        case averageTemp = "average_temp"
//        case commentCount = "comment_count"
//        case commute
//        case displayHideHeartrateOption = "display_hide_heartrate_option"
        case distance
//        case elapsedTime = "elapsed_time"
//        case elevHigh = "elev_high"
//        case elevLow = "elev_low"
//        case endLatlng = "end_latlng"
//        case externalId = "external_id"
//        case flagged
//        case fromAcceptedTag = "from_accepted_tag"
//        case gearId = "gear_id"
//        case hasHeartrate = "has_heartrate"
//        case hasKudoed = "has_kudoed"
//        case heartrateOptOut = "heartrate_opt_out"
//        case id
//        case kudosCount = "kudos_count"
//        case locationCity = "location_city"
//        case locationCountry = "location_country"
//        case locationState = "location_state"
//        case manual
//        case maxHeartrate = "max_heartrate"
//        case maxSpeed = "max_speed"
//        case movingTime = "moving_time"
//        case name
//        case photoCount = "photo_count"
//        case prCount = "pr_count"
//        case isPrivate = "private"
//        case resourceState = "resource_state"
        case sportType = "sport_type"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
//        case startLatlng = "start_latlng"
//        case sufferScore = "suffer_score"
//        case timezone
//        case totalElevationGain = "total_elevation_gain"
//        case totalPhotoCount = "total_photo_count"
//        case isTrainer = "trainer"
//        case type
//        case uploadId = "upload_id"
//        case uploadIdStr = "upload_id_str"
//        case utcOffset = "utc_offset"
//        case visibility
//        case workoutType = "workout_type"
    }
}
