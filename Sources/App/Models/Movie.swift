//
//  Movie.swift
//
//
//  Created by HoangDus on 09/11/2024.
//

import Vapor
import Fluent
import FluentMongoDriver

final class Movie: Model{
    static let schema: String = "movies"
    
    @ID(custom: .id)
    var id: ObjectId?
    @Field(key: "title")
    var title: String
    @Field(key: "banner")
    var banner: String
    @Field(key: "poster")
    var poster: String
    @Field(key: "description")
    var description: String
    @Field(key: "duration")
    var duration: String
    @Field(key: "genre")
    var genre: String
    @Field(key: "rating")
    var rating: String
    @Field(key: "year")
    var year: String
    @Field(key: "trailer")
    var trailer: String
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: ObjectId? = nil, title: String, banner: String, poster: String, description: String, duration: String, genre: String, rating: String, year: String, trailer: String ,createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.banner = banner
        self.poster = poster
        self.description = description
        self.duration = duration
        self.genre = genre
        self.rating = rating
        self.year = year
        self.trailer = trailer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    func toDTO() -> MovieDTO{
        return MovieDTO(title: title, banner: banner, poster: poster,description: description, duration: duration, genre: genre, rating: rating, year: year, trailer: trailer)
    }
}
