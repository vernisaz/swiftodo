import Foundation

class Task{
    var id: Int
    var name: String
    var description: String
    var url: String?
    var progress: Int
    var createdOn: NSDate
    var dueOn: NSDate
    
    init(id: Int, name: String, descr: String, due: NSDate, progress: Int, url: String? = nil) {
        self.id = id
        self.name = name
        self.description = descr
        self.createdOn = NSDate()
        self.dueOn = due
        self.progress = progress
        self.url = url
    }
}