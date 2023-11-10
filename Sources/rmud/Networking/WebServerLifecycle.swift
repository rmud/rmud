import Foundation
import Vapor

class WebServerLifecycle: LifecycleHandler {
    func willBoot(_ app: Application) throws {
        app.logger.info("willBoot pid=\(getpid())")
    }

    func didBoot(_ app: Application) throws {
        app.logger.info("didBoot")
    }

    func shutdown(_ app: Application) {
        app.logger.info("Shutting down")
        DispatchQueue.main.async {
            shutdownGame()
        }
    }
}
