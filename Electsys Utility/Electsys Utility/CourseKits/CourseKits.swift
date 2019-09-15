//
//  CourseKits.swift
//  Electsys Utility
//
//  Created by 法好 on 2019/9/15.
//  Copyright © 2019 yuxiqian. All rights reserved.
//

import Alamofire
import Alamofire_SwiftyJSON
import Foundation
import SwiftyJSON

class CourseKits {
    static func requestCourseTable(year: Int, term: Int,
                                   handler: @escaping ([NGCourse]) -> Void,
                                   failure: @escaping (Int) -> Void) {
        // 1 - "3"
        // 2 - "12"
        // 3 - "16"
        if term < 1 || term > 3 {
            failure(-1)
            return
        }
        let termString = CourseConst.termTable[term]

        let getParams: Parameters = [
            "xnm": year,
            "xqm": termString,
        ]

        Alamofire.request(CourseConst.requestUrl,
                          method: .get,
                          parameters: getParams).responseSwiftyJSON(completionHandler: { responseJSON in
            if responseJSON.error == nil {
                let jsonResp = responseJSON.value
                if jsonResp != nil {
                    if !PreferenceKits.hidePersonalInfo {
                        IdentityKits.studentId = jsonResp?["xsxx"]["XH"].string
                        IdentityKits.studentName = jsonResp?["xsxx"]["XM"].string
                        IdentityKits.studentNameEn = jsonResp?["xsxx"]["YWXM"].string
                    }
                    
                    var courseList: [NGCourse] = []
                
                    
                    for courseObject in jsonResp?["kbList"].arrayValue ?? [] {
                        let teachers = courseObject["xm"].stringValue.components(separatedBy: ",")
                        let teacherTitles = courseObject["zcmc"].stringValue.components(separatedBy: ",")
                        
                        let dayArrangeList = courseObject["jcs"].stringValue.components(separatedBy: "-")
                        if dayArrangeList.count != 2 {
                            continue
                        }
                        
                        let weekArrangeList = courseObject["zcd"].stringValue.components(separatedBy: CharacterSet(charactersIn: "-周"))
                        if weekArrangeList.count < 2 {
                            continue
                        }
                        
                        var dualType = ShiftWeekType.Both
                        
                        if courseObject["zcd"].stringValue.contains("(单)") {
                            dualType = .OddWeekOnly
                        } else if courseObject["zcd"].stringValue.contains("(双)") {
                            dualType = .EvenWeekOnly
                        }
                        
                        courseList.append(NGCourse(courseIdentifier: courseObject["jxbmc"].stringValue,
                                                   courseCode: courseObject["kch_id"].stringValue,
                                                   courseName: courseObject["kcmc"].stringValue,
                                                   courseTeacher: teachers,
                                                   courseTeacherTitle: teacherTitles,
                                                   courseRoom: courseObject["cdmc"].stringValue,
                                                   courseDay: courseObject["xqj"].intValue,
                                                   courseScore: courseObject["xf"].floatValue,
                                                   dayStartsAt: Int(dayArrangeList[0])!,
                                                   dayEndsAt: Int(dayArrangeList[1])!,
                                                   weekStartsAt: Int(weekArrangeList[0])!,
                                                   weekEndsAt: Int(weekArrangeList[1])!,
                                                   shiftWeek: dualType,
                                                   notes: courseObject["xkbz"].stringValue))
                    }
                    handler(courseList)
                } else {
                    failure(-3)
                }
            } else {
                failure(-2)
            }
        })
    }
}