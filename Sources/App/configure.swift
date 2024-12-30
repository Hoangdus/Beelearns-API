import NIOSSL
import Fluent
import FluentMongoDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    
    app.routes.defaultMaxBodySize = "10mb"
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.databases.use(DatabaseConfigurationFactory.mongo(
        connectionString: Environment.get("DATABASE_URL")!
    ), as: .mongo)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateLevel())
    app.migrations.add(CreatePartOfLevels())
    app.migrations.add(CreateUserStudyData())
    app.migrations.add(CreateWord())
    app.migrations.add(CreateGrammarQuestion())
    app.migrations.add(CreateTrueFalseQuestion())
    
    app.leaf.tags["dateFormat"] = DateFormatTag()
    app.views.use(.leaf)

    // register routes
    try routes(app)
}
