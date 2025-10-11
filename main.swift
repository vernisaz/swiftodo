import Foundation

struct StderrOutputStream: TextOutputStream {
    func write(_ string: String) {
        let data = Data(string.utf8)
        FileHandle.standardError.write(data)
    }
}

extension String {
    var jsonEncoded: String {
        reduce(into: "") { result, c in
            let symbol = switch c {
                case "\"": "\\\""
                case "\n": "\\n"
                case "\r": "\\r"
                case "\t": "\\t"
                case "\\": "\\\\"
                default: String(c)
            }
            result.append(symbol)
        }
    }
}

var standardError = StderrOutputStream()

var parameters = [String : String]()

if let method = ProcessInfo.processInfo.environment["REQUEST_METHOD"] {
    var query: String = ""
    if method == "POST" {
        if let inputString = readLine() {
            print("You entered: \(inputString)", to: &standardError)
            query = inputString
        } else {
            print("No input received.", to: &standardError)
        }
    } else {
        if let queryVal = ProcessInfo.processInfo.environment["QUERY_STRING"] {
            query = queryVal
            print("Your request string is: \(queryVal)", to: &standardError)
        } else {
            print("Request string not found.", to: &standardError)
            print("{\"err\":\"Request string not found.\"}")
        }
    }
    let pairs = query.split(separator: "&")
    for pair in pairs {
        let nameVal = pair.split(separator: "=", maxSplits: 1)
        if let unwrappedName = nameVal[0].removingPercentEncoding {
            parameters[unwrappedName] = nameVal[1].removingPercentEncoding ?? ""
        }
    }
}

let op: String? = parameters["op"]
print("Status: 200 OK\r")
print("Content-type: application/json\r\n\r")
switch  op ?? "unknown" {
case "create":
    let _ = DBManager()
    print("created db.", to: &standardError)

    print("{\"message\":\"The table's created.\",\"status\":\"Ok\"}")
case "insert":
    let db = DBManager()
    if let dateString = parameters["due"] {//"2025-10-08 21:18:00" // Your date string
    
        let dateFormatter = DateFormatter()
        
        // Set the date format to match your string
        dateFormatter.dateFormat = "yyyy-MM-dd" // HH:mm:ss"
        
        // Convert the string to a Date object
        if let date = dateFormatter.date(from: dateString) {
            // Cast the Date to NSDate
            let nsDate = date as NSDate
            if !db.insertTask(name: (parameters["name"] ?? "new task").jsonEncoded,
                description: (parameters["description"] ?? "description of task").jsonEncoded, 
            due: nsDate) {
                print("{\"err\":\"Couldn't insert the task.\"}")
            } else {
                print("{\"message\":\"The task inserted.\",\"status\":\"Ok\"}")
            }
            print("NSDate object: \(nsDate)", to: &standardError)
        } else {
            print("Could not convert string \(dateString) to date.", to: &standardError)
            print("{\"err\":\"Wrong date format \(dateString).\"}")
        }
    }
case "update":
    let id = Int(parameters["id"] ?? "0") ?? 0
    if id == 0 {
        print("{\"err\":\"No id of updated record\"}")
        break
    }
    let db = DBManager()
    if let dateString = parameters["due"] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: dateString) {
            // Cast the Date to NSDate
            let nsDate = date as NSDate
            //print("NSDate object: \(nsDate)", to: &standardError)
            if !db.updateTask(id: id, name: (parameters["name"] ?? "new task").jsonEncoded,
                description: (parameters["description"] ?? "description of task").jsonEncoded, 
                progress: Int(parameters["progress"] ?? "0") ?? 0,
                due: nsDate) {
                print("{\"err\":\"Couldn't update the task.\"}")
            } else {
                print("{\"message\":\"The task updated.\",\"status\":\"Ok\"}")
            }
        } else {
            print("Could not convert string \(dateString) to date.", to: &standardError)
            print("{\"err\":\"Wrong date format \(dateString).\"}")
        }
    }
case "all":
    let db = DBManager()
    var res = "{"
    let tasks = db.getAllTasks()
    // should return a tuple with error
    res += "\"status\":\"Ok\", \"entries\": ["
    for task in tasks {
        res += "{\"name\":\"\(task.name)\", \"id\":\(task.id), \"description\":\"\(task.description)\", \"progress\":\(task.progress), \"due\":\(task.dueOn.timeIntervalSince1970)},"
    }
    res += "{\"name\":\"new task\", \"id\":0, \"description\":\"\", \"progress\":0, \"due\":0}]}"
    print(res)
case "delete":
    let id = Int(parameters["id"] ?? "0") ?? 0
    if id == 0 {
        print("{\"err\":\"No id of updated record\"}")
        break
    }
    let db = DBManager()
    if db.deleteTask(id: id) {
        print("{\"message\":\"The task deleted.\",\"status\":\"Ok\"}")
    } else {
        print("{\"err\":\"Couldn't delete the task.\"}")
    }
default:
    print("{\"err\":\"No known \(op ?? "no value").\"}")
}
