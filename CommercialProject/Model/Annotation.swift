//
//  Annotation.swift
//  CommercialProject
//
//  Created by Vũ Quý Đạt  on 27/11/2020.
//

import Foundation

final class Annotation: Codable {
    var annotationImageName: String
    var image: String
    
    init(annotationImageName: String, image: String) {
        self.annotationImageName = annotationImageName
        self.image = image
    }
}

final class AnnotationUpload: Codable {
    var name: String
    var latitude: String
    var longitude: String
    var description: String
    var file: File
    
    init(name: String, description: String, latitude: String, longitude: String, file: File) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.description = description
        self.file = file
    }
}

final class AnnotationInfo: Codable {
    var id: Int
    var latitude: String
    var longitude: String
    var name: String
    var description: String
    
    init(id: Int, latitude: String, longitude: String, name: String, description: String) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.description = description
    }
}

final class CheckTotalOfAnnotationsReponse: Codable {
    var shouldUpdate: Bool
    init(shouldUpdate: Bool) {
        self.shouldUpdate = shouldUpdate
    }
}
