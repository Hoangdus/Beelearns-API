import Fluent
import Vapor
import CoreXLSX
import Foundation

func routes(_ app: Application) throws {
    
    var statusMessage = ""
    var mode = ""
    
    app.get("login") { req async throws -> View in
        try await req.view.render("login")
    }
    
    app.get("admin") { req async throws -> View in
        guard let listMode: String = req.query["list"] else { return try await req.view.render("index", ["title":"Admin"]) }
        
        //        struct viewData: Codable{
        //            var title: String
        //            var mode: String = "test"
        //            var list
        //
        //            init(){
        //                switch self.mode{
        //                case "words":
        //                    self.list: [Word] = try await Word.query(on: req.db).all()
        //                default:
        //                    var list: [String] = ["blank","blank","blank"]
        //                }
        //            }
        //
        //        }
        print(statusMessage)
        
        switch listMode{
        case "words":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [Word]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await Word.query(on: req.db).all(), listMode: listMode))
        case "truefalse":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [TrueFalseQuestion]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await TrueFalseQuestion.query(on: req.db).all(), listMode: listMode))
        case "grammar":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [GrammarQuestion]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await GrammarQuestion.query(on: req.db).all(), listMode: listMode))
        case "music":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [Music]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await Music.query(on: req.db).all(), listMode: listMode))
        case "movie":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [Movie]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await Movie.query(on: req.db).all(), listMode: listMode))
        case "podcast":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [Podcast]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await Podcast.query(on: req.db).all(), listMode: listMode))
        case "user":
            mode = listMode
            struct viewData: Codable{
                var title: String
                var list: [User]
                var listMode: String
            }
            return try await req.view.render("index", viewData(title: listMode, list: try await User.query(on: req.db).all(), listMode: listMode))
            
        default:
            return try await req.view.render("index", ["title":"Admin"])
        }
        
    }
    
    // /upload-data?mode=
    app.post("upload-data") { req throws in
        struct InputExcelSheet: Content{
            var file: File
        }
        
        //        print(req)
        //        print(req.peerAddress?.ipAddress)
        
        var redirectString = "admin?list=\(mode)"
        
        let inputXlxs = try req.content.decode(InputExcelSheet.self)
        let mode: String = inputXlxs.file.filename
        let xlsxData = Data(buffer: inputXlxs.file.data)
        
        if(inputXlxs.file.extension != "xlsx"){
            statusMessage = "not an excel sheet"
            return req.redirect(to: redirectString)
        }
        
        var items = []
        
        switch mode{
        case "word.xlsx":
            redirectString = "admin?list=words"
            items = try parseXLSX(_: Word.self, XLSXData: xlsxData)
        case "truefalse.xlsx":
            redirectString = "admin?list=truefalse"
            items = try parseXLSX(TrueFalseQuestion.self, XLSXData: xlsxData)
            print(items.count)
        case "grammar.xlsx":
            redirectString = "admin?list=grammar"
            items = try parseXLSX(GrammarQuestion.self, XLSXData: xlsxData)
        case "movie.xlsx":
            redirectString = "admin?list=movie"
            items = try parseXLSX(Movie.self, XLSXData: xlsxData)
        case "music.xlsx":
            redirectString = "admin?list=music"
            items = try parseXLSX(Music.self, XLSXData: xlsxData)
        case "podcast.xlsx":
            redirectString = "admin?list=podcast"
            items = try parseXLSX(Podcast.self, XLSXData: xlsxData)
        case "IPA.xlsx":
            redirectString = "admin?list=music"
            _ = try parseXLSX(IPA.self, XLSXData: xlsxData)
        default:
            statusMessage = "wrong file"
            return req.redirect(to: redirectString)
            //            throw Abort(.badRequest)
        }
        
        if(!items.isEmpty){
            for item in items{
                let modelItem: any Model = item as! any Model
                _ = modelItem.create(on: req.db)
            }
        }
        
        statusMessage = "done"
        return req.redirect(to: redirectString)
    }
    
    app.post("upload-file") { req -> EventLoopFuture<String> in
        struct InputFile: Content{
            var file: File
        }
        
        let inputFile = try req.content.decode(InputFile.self)
        
        let path = app.directory.publicDirectory + inputFile.file.filename
        return app.fileio.openFile(path: path, mode: .write, flags: .allowFileCreation(posixMode: 0x744), eventLoop: req.eventLoop)
            .flatMap {handle in
                req.application.fileio.write(fileHandle: handle, buffer: inputFile.file.data, eventLoop: req.eventLoop)
                    .flatMapThrowing { _ in
                        try handle.close()
                        return inputFile.file.filename
                    }
            }
    }
    
    app.post("auth", "register") { req async throws -> Response in
        let registerDTO = try req.content.decode(RegisterDTO.self)
        
        // Check existing user
        let existingUser = try await User.query(on: req.db).filter(\.$email == registerDTO.email).first()
        if existingUser != nil {
            throw Abort(.conflict, reason: "User already exists.")
        }
        
        // create new user
        let user = User(email: registerDTO.email, username: registerDTO.username, password: registerDTO.password)
        try await user.save(on: req.db)
        try await UserStudyData(userEmail: registerDTO.email).save(on: req.db)
        
        let response = ["message": "Register successfully"]
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
    }
    
    app.post("auth", "login") { req async throws -> UserDTO in
        let loginDTO = try req.content.decode(LoginDTO.self)
        
        print(loginDTO)
        
        guard let user = try await User.query(on: req.db).filter(\.$email == loginDTO.email).filter(\.$password == loginDTO.password).first() else { throw Abort(.notFound) }
        
        return user.toDTO()
    }
    
    app.put("auth", "change-password") {req async throws -> Response in
        let changepasswordDTO = try req.content.decode(ChangePasswordDTO.self)
        
        let user = try await User.query(on: req.db).filter(\.$email == changepasswordDTO.email).first()
        
        guard let existingUser = user else {
            throw Abort(.notFound, reason: "User not found.")
        }
        
        guard existingUser.password == changepasswordDTO.oldPassword else {
            throw Abort(.unauthorized, reason: "Old password is incorrect.")
        }
        
        existingUser.password = changepasswordDTO.newPassword
        try await existingUser.update(on: req.db)
        
        let response = ["message": "Password changed successfully."]
        
        return Response(status: .ok, body: .init(data: try JSONEncoder().encode(response)))
    }
    
    try app.register(collection: WordController())
    try app.register(collection: UserController())
    try app.register(collection: TrueFalseQuestionController())
    try app.register(collection: GrammarQuestionController())
    try app.register(collection: MusicController())
    try app.register(collection: PodcastController())
    try app.register(collection: IPAController())
    try app.register(collection: MovieController())
    try app.register(collection: QuestionController())
    try app.register(collection: LevelController())
    try app.register(collection: PartOfLevelController())
}
