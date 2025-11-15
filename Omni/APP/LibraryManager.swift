import Foundation
import SwiftUI

// MARK: - Models
struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isActive: Bool
    var files: [LibraryFile]
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, isActive: Bool = false, files: [LibraryFile] = []) {
        self.id = id
        self.name = name
        self.isActive = isActive
        self.files = files
        self.createdAt = Date()
    }
}

struct LibraryFile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var url: URL
    var content: String
    var addedAt: Date
    
    init(id: UUID = UUID(), name: String, url: URL, content: String) {
        self.id = id
        self.name = name
        self.url = url
        self.content = content
        self.addedAt = Date()
    }
}

// MARK: - Library Manager
@MainActor
class LibraryManager: ObservableObject {
    static let shared = LibraryManager()
    
    @Published var projects: [Project] = []
    
    private let projectsKey = "com.omni.library.projects"
    private let fileManager = FileManager.default
    
    init() {
        loadProjects()
    }
    
    // MARK: - New Chat-Specific Helpers
    
    /// Finds and returns a project by its unique ID.
    /// This is used by ContentViewModel to find the project attached to a chat session.
    func getProject(by id: UUID) -> Project? {
        return projects.first(where: { $0.id == id })
    }
    
    /// Generates the full-text context for a *specific* project.
    /// This is the new way to get context for a single chat session.
    func getContext(for project: Project) -> String {
        let files = project.files
        guard !files.isEmpty else { return "" }
        
        var context = "# Reference Library Context: \(project.name)\n(This chat is using \(project.files.count) file(s) as a source of truth.)\n\n---\n\n"
        
        for file in files {
            context += "## File: \(file.name)\n\n"
            // We use the 'content' property you already have in your model
            context += "\(file.content)\n\n"
            context += "---\n\n"
        }
        return context
    }
    
    // MARK: - Project Management
    
    func createProject(name: String) {
        let newProject = Project(name: name)
        projects.append(newProject)
        saveProjects()
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        saveProjects()
    }
    
    func renameProject(_ project: Project, newName: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].name = newName
            saveProjects()
        }
    }
    
    func setActiveProject(_ project: Project) {
        // Deactivate all projects first
        for index in projects.indices {
            projects[index].isActive = false
        }
        
        // Activate the selected project
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].isActive = true
            saveProjects()
        }
    }
    
    func toggleProjectActive(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            if projects[index].isActive {
                // If turning off, just deactivate
                projects[index].isActive = false
            } else {
                // If turning on, deactivate all others first
                for i in projects.indices {
                    projects[i].isActive = false
                }
                projects[index].isActive = true
            }
            saveProjects()
        }
    }
    
    // This is still used by your Settings view
    var activeProject: Project? {
        projects.first { $0.isActive }
    }
    
    // MARK: - File Management
    func addFile(to project: Project, url: URL) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("Couldn't access security scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let newFile = LibraryFile(name: url.lastPathComponent, url: url, content: content)
            
            // Check if file already exists
            if !projects[index].files.contains(where: { $0.url == url }) {
                projects[index].files.append(newFile)
                saveProjects()
            }
        } catch {
            print("Error reading file: \(error.localizedDescription)")
        }
    }
    
    func removeFile(_ file: LibraryFile, from project: Project) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[projectIndex].files.removeAll { $0.id == file.id }
        saveProjects()
    }
    
    // Get all files from active project for chat context (Old logic, still used by old VM code)
    func getActiveProjectFiles() -> [LibraryFile] {
        guard let active = activeProject else { return [] }
        return active.files
    }
    
    func getActiveProjectContext() -> String {
        let files = getActiveProjectFiles()
        guard !files.isEmpty else { return "" }
        
        var context = "# Reference Library Context\n\n"
        for file in files {
            context += "## File: \(file.name)\n\n"
            context += "\(file.content)\n\n"
            context += "---\n\n"
        }
        return context
    }
    
    // MARK: - Persistence
    private func saveProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            UserDefaults.standard.set(data, forKey: projectsKey)
        } catch {
            print("Error saving projects: \(error.localizedDescription)")
        }
    }
    
    private func loadProjects() {
        guard let data = UserDefaults.standard.data(forKey: projectsKey) else {
            // Create a default project if none exist
            projects = [Project(name: "Default Project", isActive: false)] // Changed default to false
            saveProjects()
            return
        }
        
        do {
            projects = try JSONDecoder().decode([Project].self, from: data)
        } catch {
            print("Error loading projects: \(error.localizedDescription)")
            projects = [Project(name: "Default Project", isActive: false)]
        }
    }
}
