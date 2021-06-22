import Vapor
import Queues
import QueuesMemoryDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.queues.use(.memory)
    
    //Register jobs
    let emailJob = EmailJob()
    app.queues.add(emailJob)
    
    // 定时任务
    app.queues.schedule(CleanupJob())
        .daily()
        .at(.midnight)
    
    // 默认执行
    try app.queues.startInProcessJobs(on: .default)
    try app.queues.startScheduledJobs()
    
    // register routes
    try routes(app)
}

// 路由
func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    // http://127.0.0.1:8080/email
    app.get("email") { req -> EventLoopFuture<String> in
        return req
            .queue
            .dispatch(
                EmailJob.self,
                .init(to: "email@email.com", message: "message")
            ).map { "done" }
    }
}
// 指定任务
struct Email: Codable {
    let to: String
    let message: String
}

struct EmailJob: Job {
    typealias Payload = Email

    func dequeue(_ context: QueueContext, _ payload: Email) -> EventLoopFuture<Void> {
        // This is where you would send the email
        return context.eventLoop.future()
    }

    func error(_ context: QueueContext, _ error: Error, _ payload: Email) -> EventLoopFuture<Void> {
        // If you don't want to handle errors you can simply return a future. You can also omit this function entirely.
        return context.eventLoop.future()
    }
}

// 定时任务
struct CleanupJob: ScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) -> EventLoopFuture<Void> {
        // Do some work here, perhaps queue up another job.
        return context.eventLoop.makeSucceededFuture(())
    }
}
