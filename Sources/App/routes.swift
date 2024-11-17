import Fluent
import Vapor
import CoreXLSX
import Foundation

func routes(_ app: Application) throws {
    
    var statusMessage = ""
    //    struct AdminPageData: Encodable{
    //        var statusMessage = ""
    //        var testObjects = []
    //    }
    
    app.get("admin") { req async throws in
        //try await req.view.render("index", AdminPageData(statusMessage: statusMessage, testObjects: testObjects))
        try await req.view.render("index", ["statusMessage": statusMessage])
    }
    
    // /upload-data?mode=
    app.post("upload-data") { req throws in
        struct InputExcelSheet: Content{
            var file: File
        }
        
        //        print(req.peerAddress?.hostname)
        //        print(req.peerAddress?.ipAddress)
        
        let inputXlxs = try req.content.decode(InputExcelSheet.self)
        let mode: String = inputXlxs.file.filename
        let xlsxData = Data(buffer: inputXlxs.file.data)
        
        if(inputXlxs.file.extension != "xlsx"){
            statusMessage = "not an excel sheet"
            return req.redirect(to: "admin")
        }
        
        switch mode{
        case "word":
            _ = try parseXLSX(_: Word.self, XLSXData: xlsxData).create(on: req.db)
        case "truefalse":
            _ = try parseXLSX(TrueFalseQuestion.self, XLSXData: xlsxData).create(on: req.db)
        case "grammar":
            break
        case "movie":
            break
        case "music":
            break
        case "podcast":
            break
        case "IPA":
            break
        default:
            statusMessage = "wrong file"
            return req.redirect(to: "admin")
//            throw Abort(.badRequest)
        }
        
        statusMessage = "done"
        return req.redirect(to: "admin")
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
    
    app.post("auth", "register") { req async throws -> String in
        let registerDTO = try req.content.decode(RegisterDTO.self)
        
        // Check existing user
        let existingUser = try await User.query(on: req.db).filter(\.$email == registerDTO.email).first()
        if existingUser != nil {
            throw Abort(.conflict, reason: "User already exists.")
        }
        
        // create new user
        let user = User(username: registerDTO.username, email: registerDTO.email, password: registerDTO.password)
        try await user.save(on: req.db)
        
        return "Register successfully"
    }
    
    app.post("auth", "login") { req async throws -> UserDTO in
        let loginDTO = try req.content.decode(LoginDTO.self)
        
        print(loginDTO)
        
        guard let user = try await User.query(on: req.db).filter(\.$email == loginDTO.email).filter(\.$password == loginDTO.password).first() else { throw Abort(.notFound) }
        
        
        return user.toDTO()
    }
    
    app.put("auth", "change-password") {req async throws -> String in
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
        
        return "Password changed successfully."
    }
    
    try app.register(collection: WordController())
    try app.register(collection: UserController())
    try app.register(collection: TrueFalseQuestionController())
    try app.register(collection: GrammarQuestionController())
    try app.register(collection: MusicController())
    try app.register(collection: PodcastController())
    try app.register(collection: IPAController())
    try app.register(collection: MovieController())
}
