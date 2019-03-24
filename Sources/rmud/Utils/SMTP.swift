import Foundation

class SMTP {
    let hostname: String
    let email: String
    let password: String
    
    init(hostname: String, email: String, password: String) {
        self.hostname = hostname
        self.email = email
        self.password = password
    }
    
    func sendEmail(from: String, to: String, subject: String, text: String) {
        let text = """
            From: \(from)
            To: \(to)
            Subject: \(subject)
            
            """ + text
        
        let (result, code) = shell(
            launchPath: "Tools/send_email.sh", arguments: [hostname, email, password, from, to], input: text)
        guard code == 0 else {
            logError("Unable to send email with confirmation code")
            return
        }
        if settings.debugLogSendEmailResult, let result = result {
            log("SMTP.sendEmail result: \(result)")
        }
    }
}
