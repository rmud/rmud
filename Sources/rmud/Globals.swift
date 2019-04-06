import Foundation

let accounts = Accounts.sharedInstance
let areaManager = AreaManager.sharedInstance
let ban = Ban.sharedInstance
let classes = Classes.sharedInstance
let commandInterpreter = CommandInterpreter.sharedInstance
let db = Db.sharedInstance
let dns = Dns.sharedInstance
let endings = Endings.sharedInstance
let filenames = Filenames.sharedInstance
let gameTime = GameTime.sharedInstance
let messages = Messages.sharedInstance
let morpher = Morpher.sharedInstance
let networking = Networking.sharedInstance
let players = Players.sharedInstance
let settings = Settings.sharedInstance
let socials = Socials.sharedInstance
let spells = Spells.sharedInstance
let telnet = Telnet.sharedInstance
let textFiles = TextFiles.sharedInstance

//var mudShutdown = false
var timeUntilReboot: Int? = nil // ticks until reboot, nil is off
