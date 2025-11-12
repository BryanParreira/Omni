import SwiftUI

struct LibrarySettingsView: View {
    @StateObject private var libraryManager = LibraryManager.shared
    @State private var showingNewProjectSheet = false
    @State private var newProjectName = ""
    @State private var selectedProject: Project?
    @State private var showingRenameAlert = false
    @State private var renameText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library Projects")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showingNewProjectSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Project")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FF6B6B"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Projects List
            if libraryManager.projects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(Color(hex: "FF6B6B"))
                    Text("No projects yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Create a project to organize your files")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(libraryManager.projects) { project in
                            ProjectRow(
                                project: project,
                                onToggle: {
                                    libraryManager.toggleProjectActive(project)
                                },
                                onRename: {
                                    selectedProject = project
                                    renameText = project.name
                                    showingRenameAlert = true
                                },
                                onDelete: {
                                    libraryManager.deleteProject(project)
                                },
                                onAddFiles: {
                                    selectFiles(for: project)
                                },
                                onRemoveFile: { file in
                                    libraryManager.removeFile(file, from: project)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet(
                projectName: $newProjectName,
                onCreate: {
                    libraryManager.createProject(name: newProjectName)
                    newProjectName = ""
                    showingNewProjectSheet = false
                },
                onCancel: {
                    newProjectName = ""
                    showingNewProjectSheet = false
                }
            )
        }
        .alert("Rename Project", isPresented: $showingRenameAlert) {
            TextField("Project Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                selectedProject = nil
                renameText = ""
            }
            Button("Rename") {
                if let project = selectedProject, !renameText.isEmpty {
                    libraryManager.renameProject(project, newName: renameText)
                }
                selectedProject = nil
                renameText = ""
            }
        }
    }
    
    private func selectFiles(for project: Project) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Files"
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.text, .plainText, .pdf, .data]
        
        guard let window = NSApp.keyWindow else { return }
        
        openPanel.beginSheetModal(for: window) { response in
            if response == .OK {
                for url in openPanel.urls {
                    libraryManager.addFile(to: project, url: url)
                }
            }
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    let onToggle: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onAddFiles: () -> Void
    let onRemoveFile: (LibraryFile) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Project Header
            HStack {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "folder.fill")
                    .foregroundColor(project.isActive ? Color(hex: "FF6B6B") : .gray)
                
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(project.isActive ? .primary : .secondary)
                
                if project.isActive {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FF6B6B").opacity(0.2))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .cornerRadius(4)
                }
                
                Text("(\(project.files.count) files)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 8) {
                    Toggle("", isOn: .init(
                        get: { project.isActive },
                        set: { _ in onToggle() }
                    ))
                    .toggleStyle(.switch)
                    .tint(Color(hex: "FF6B6B"))
                    .labelsHidden()
                    
                    Button(action: onAddFiles) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color(hex: "FF6B6B"))
                    }
                    .buttonStyle(.plain)
                    .help("Add files")
                    
                    Button(action: onRename) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                    .help("Rename project")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete project")
                }
            }
            .padding()
            .background(project.isActive ? Color(hex: "FF6B6B").opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Files List (when expanded)
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if project.files.isEmpty {
                        Text("No files yet. Click + to add files.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 44)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(project.files) { file in
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(Color(hex: "FF6B6B"))
                                    .font(.caption)
                                
                                Text(file.name)
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text(file.addedAt, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { onRemoveFile(file) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.leading, 44)
                .padding(.trailing, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - New Project Sheet
struct NewProjectSheet: View {
    @Binding var projectName: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Project")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Project Name", text: $projectName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button("Create") {
                    onCreate()
                }
                .keyboardShortcut(.return)
                .disabled(projectName.isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "FF6B6B"))
            }
        }
        .padding(30)
        .frame(width: 400)
    }
}

// MARK: - Color Extension

// MARK: - Preview
#Preview {
    LibrarySettingsView()
}
