import Foundation
import SQLite3

class DBManager{
    init(){
        db = openDatabase()
        createTaskTable()
    }
    
    let dataPath: String = "TodoDB"
    var db: OpaquePointer?
    var standardError = StderrOutputStream()
    
    // Create DB
    func openDatabase()->OpaquePointer?{
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dataPath)
        
        var db: OpaquePointer? = nil
        if sqlite3_open(filePath.path, &db) != SQLITE_OK{
            //debugPrint("Cannot open DB.")
            print("Cannot open DB.", to: &standardError)
            return nil
        }
        else{
            print("DB successfully created.", to: &standardError)
            return db
        }
    }
    
    // Delete DB
    func deleteDatabase() -> Bool {
        let filePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(dataPath)
    
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: filePath)
            print("File deleted successfully at: \(filePath.lastPathComponent)", to: &standardError)
            db = nil
            return true
        } catch {
            print("Error deleting file: \(error.localizedDescription)", to: &standardError)
            return false
        }
    }    
    
    // Create users table
    func createTaskTable() {
        let createTableString = """
            CREATE TABLE IF NOT EXISTS Task (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                url TEXT,
                createdOn INTEGER,
                dueOn INTEGER,
                progress INTEGER
            );
        """

        var createTableStatement: OpaquePointer? = nil

        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Task table is created successfully.", to: &standardError)
            } else {
                print("Task table creation failed.", to: &standardError)
            }
        } else {
            print("Task table creation failed.", to: &standardError)
        }

        sqlite3_finalize(createTableStatement)
    }

    
    // Add a new task with registration screen (name, description, dueOn.)
    // Progress of the task has to be updated later
    func insertTask(name: String, description: String, due: NSDate, url: Optional<String> = .none) -> Bool {
        let tasks = getAllTasks()
        
        // Check task id  is exist in Task table or not
        for task in tasks {
            if task.name == name {
                return false
            }
        }
        
        let insertStatementString = "INSERT INTO Task (name, description, dueOn, createdOn, progress, url) VALUES (?, ?, ?, ?, ?, ?);"
        var insertStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, (description as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 3, Int32(due.timeIntervalSince1970))
            sqlite3_bind_int(insertStatement, 4, Int32(Date().timeIntervalSince1970))
            sqlite3_bind_int(insertStatement, 5, 0)
            if let unwrappedUrl = url {
                sqlite3_bind_text(insertStatement, 6, (unwrappedUrl as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(insertStatement, 6)
            }
            // assign empty value to address

            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Task is created successfully.", to: &standardError)
                sqlite3_finalize(insertStatement)
                return true
            } else {
                print("Could not add.", to: &standardError)
                return false
            }
        } else {
            print("INSERT statement is failed.", to: &standardError)
            return false
        }
    }

    // Get all tasks from Task table
    func getAllTasks() -> [Task] {
        let queryStatementString = "SELECT * FROM Task;"
        var queryStatement: OpaquePointer? = nil
        var tasks : [Task] = []
        if sqlite3_prepare_v2(db,  queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let description = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                //let cString = sqlite3_column_text(queryStatement, 3)
                let url =
                if let unwrappedPointer = sqlite3_column_text(queryStatement, 3) {
                    String(describing: String(cString: unwrappedPointer))
                } else {
                    ""
                }
 
                let dueDate = NSDate(timeIntervalSince1970: TimeInterval(sqlite3_column_int(queryStatement, 5)))
                let progress = Int(sqlite3_column_int(queryStatement, 6))
                
                tasks.append(Task(id: Int(id), name: name, descr: description, due: dueDate, progress: progress, url: url))
                print("Task Details:", to: &standardError)
                print("\(id) | \(name) | \(description) | \(url) | \(dueDate) | \(progress)", to: &standardError)
            }
        } else {
            print("SELECT statement is failed.", to: &standardError)
        }
        sqlite3_finalize(queryStatement)
        return tasks
    }
   
    // Get unfinished tasks which overdue
    func getUnfinishedTaskbyDue(due:NSDate? = nil) -> [Task] {
        let queryStatementString = "SELECT * FROM Task WHERE dueOn <= ? AND progress < 100;"
        var queryStatement: OpaquePointer? = nil
        var task : [Task] = []
        var varDue = due
        if varDue == nil {
            varDue = NSDate()
        }
        if sqlite3_prepare_v2(db,  queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            //sqlite3_bind_text(queryStatement, 1, (description as NSString).utf8String, -1, nil)
            sqlite3_bind_int(queryStatement, 1, Int32(varDue!.timeIntervalSince1970))
            
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = String(describing: String(cString: sqlite3_column_text(queryStatement, 1)))
                let description = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                let dueDate = NSDate(timeIntervalSince1970: TimeInterval(sqlite3_column_int(queryStatement, 5)))
                let progress = sqlite3_column_int(queryStatement, 6)
                
                task.append(Task(id: Int(id), name: name, descr: description, due: dueDate, progress: Int(progress)))
                print("Task Details:", to: &standardError)
                print("\(id) | \(name) | \(description) | \(dueDate) | \(progress)", to: &standardError)
            }
        } else {
            print("SELECT statement is failed.", to: &standardError)
        }
        sqlite3_finalize(queryStatement)
        return task
    }

    // Update task on Task table
    func updateTask(id: Int, name: String, description: String, progress: Int, due: NSDate, url: String? = nil) -> Bool{
        let updateStatementString = "UPDATE Task SET name=?, description=?, progress=?, dueOn=?, url=? WHERE id=?;"
        var updateStatement: OpaquePointer? = nil
 
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, (description as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 3, Int32(progress))
            sqlite3_bind_int(updateStatement, 4, Int32(due.timeIntervalSince1970))
            if let unwrappedUrl = url {
                sqlite3_bind_text(updateStatement, 5, (unwrappedUrl as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(updateStatement, 5)
            }
            sqlite3_bind_int(updateStatement, 6, Int32(id))

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Task updated successfully.", to: &standardError)
                sqlite3_finalize(updateStatement)
                return true
            } else {
                print("Could not update.", to: &standardError)
                return false
            }
        } else {
            print("UPDATE statement is failed.", to: &standardError)
            return false
        }
    }
    
    func deleteTask(id: Int) -> Bool {
        let updateStatementString = "DELETE FROM Task  WHERE id=?;"
        var updateStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(updateStatement, 1, Int32(id))

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Task deleted successfully.", to: &standardError)
                sqlite3_finalize(updateStatement)
                return true
            } else {
                print("Could not delete.", to: &standardError)
                return false
            }
        } else {
            print("DELETE statement is failed.", to: &standardError)
            return false
        }
    }
}