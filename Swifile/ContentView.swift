//
//  ContentView.swift
//  Swifile
//
//  Created by Nguyen Bao on 04/02/2024.
//  Views originally made by SpeedyFriend67.
//

import SwiftUI
import UIKit
import Foundation

@ViewBuilder
func makeTitleWithSecondary(_ mainTitle:String, _ secondaryTitle: String) -> some View {
	HStack {
		Text(mainTitle)
			.padding(.vertical, 6)
		Spacer()
		Text(secondaryTitle)
			.font(.subheadline)
			.foregroundColor(.secondary)
			.padding(.vertical, 6)
	}
}

struct DirListView: View {
	@State private var contents: [ContentItem] = []
	@State private var searchText: String = ""
	@State private var skipHiddenFiles: Bool = false
	
	@State private var gotErrors: Bool = false
	@State private var errorString: String = ""
	
	@State private var settingsCalled: Bool = false
	@State private var newItemCalled: Bool = false
	@State private var callFavourites: Bool = false
	@State private var callActions: Bool = false
	@State private var callCreateDialog: Bool = false
	@State private var deleteConfirm: Bool = false

	@State private var createType: Int = 0 // 1 = file, 2 = folder
	@State private var targetCreate: String = ""
	
	@AppStorage("showHiddenFiles") var showHiddenFiles: Bool = true
	@AppStorage("sortBy") var sortBy: SortOption = .name
	@AppStorage("favourites") var favourites: [String] = []
	
	let folderURL: URL
	let folderName: String
	
	init(folderURL: URL) {
		self.folderURL = folderURL
		self.folderName = folderURL.lastPathComponent
	}
	
	var body: some View {
		if errorString == "" {
			List(filteredContents().sorted(by: sortBy.sortingComparator), id: \.id) { contentItem in
				NavigationLink {
					if contentItem.isFolder || contentItem.isSymbolicLink {
						DirListView(folderURL: URL(fileURLWithPath: contentItem.realPath))
					} else {
						Text("Hmm, this feature is not implemented.")
					}
				} label: {
					makeListEntryLabel(item: contentItem)
				}

				.padding(.vertical, 6)

				.swipeActions(allowsFullSwipe: true) {
					Button {
						if favourites.contains(contentItem.url.path) == false {
							favourites.append(contentItem.url.path)
						} else {
							favourites.removeAll { $0 == contentItem.url.path }
						}
					} label: {
						Label("Star", systemImage: "star")
					}
					.tint(.yellow)
					
					Button {
						callActions = true
					} label: {
						Label("More", systemImage: "option")
					}
					.tint(.indigo)
					
					Button {
						deleteConfirm = true
					} label: {
						Label("Delete", systemImage: "trash")
					}
					.tint(.red)
				}

				// delete confirmation
				.alert(isPresented: $deleteConfirm, content: {
					Alert(
						title: Text("Delete confirmation"),
						message: Text("Are you sure want to delete this? No revert!"),
						primaryButton: .destructive(Text("Yes"), action: {
							deleteConfirm = false
							deleteItem(at: contentItem.url)
						}),
						secondaryButton: .default(Text("No"), action: {
							deleteConfirm = false
						})
					)
				})

				// actions
				.sheet(isPresented: $callActions, content: {
					DirListItemActions(item: contentItem, isPresented: $callActions, contents: $contents)
				})
			}
			// navigation
			.navigationBarTitle(folderURL.path)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					HStack {
						Picker("", selection: $sortBy, content: {
							ForEach(SortOption.allCases, id: \.self) { option in
								Text(option.rawValue).tag(option)
							}
						})
						.pickerStyle(MenuPickerStyle())
						.labelStyle(.iconOnly)
						
						Button("", systemImage: "doc.badge.plus", action: { newItemCalled = true })
							.labelStyle(.iconOnly)
						
						Button("", systemImage: "gear", action: { settingsCalled = true })
							.labelStyle(.iconOnly)
					}
				}

				ToolbarItem(placement: .bottomBar) {
					HStack {
						Button("Queue", action: {}) // View not implemented
						Button("Favourites", action: { callFavourites = true }) // View not implemented
						Button("Refresh", action: { loadContents(folderURL.path) })
					}
				}
			}

			// search bar
			.searchable(text: $searchText, prompt: Text("Find for an item"))

			// (re)load contents on show
			.onAppear { contents = loadContents(folderURL.path) }

			// create file/folder sheets
			.actionSheet(isPresented: $newItemCalled) {
				ActionSheet(
					title: Text("What kind of item do you want to create?"),
					buttons: [
						.default(Text("File"), action: { createType = 1; callCreateDialog = true }),
						.default(Text("Folder"), action: { createType = 2; callCreateDialog = true }),
						.cancel()
					]
				)
			}

			// error alert
			.alert(isPresented: $gotErrors, content: {
				Alert(
					title: Text("An error occured!"),
					message: Text(errorString),
					dismissButton: .default(Text("Ok then")) {
						gotErrors = false
						errorString = ""
					}
				)
			})

			// settings view
			.sheet(isPresented: $settingsCalled, content: {
				SettingsView(isPresented: $settingsCalled)
			})

			.sheet(isPresented: $callFavourites, content: {
				List(favourites.sorted(by: sortBy.sortingComparatorStr), id:\.self) { favourite in
					Text(favourite)
				}
			})

		} else {
			Text("An error occured!").font(.title2.bold())

			Text(errorString).font(.title3)

			LogView(text: errorString)
		}
	}
	
	private func makeListEntryLabel(item: ContentItem) -> some View {
		let url = item.url
		var icon: String = "doc"
		if item.isFolder {
			icon = "folder"
		}
		return Label(url.lastPathComponent, systemImage: icon)
	}

	private func loadContents(_ target: String) -> [ContentItem] {
		var items = contentsOfDirectory(target)
		if skipHiddenFiles {
			items.removeAll { $0.hasPrefix(".") }
		}
		return items.map { item in
			let url = URL(fileURLWithPath: target + "/\(item)")
			let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
			let isSymLink = (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink ?? false
			let fileSize = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
			let modificationDate = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date()
			let realPath = url.resolvingSymlinksInPath().path
			let childrens: [ContentItem]?
			if (isDir) {
				childrens = loadContents(target + "/\(item)")
			} else {
				childrens = nil
			}
			
			return ContentItem(url: url, isFolder: isDir, isSymbolicLink: isSymLink,
								fileSize: fileSize, modificationDate: modificationDate, realPath: realPath, childrens: childrens)
		}
	}
	
	private func deleteItem(at url: URL) {
		// TODO: Handle output
		let test = runHelper(["d", url.path])
		if (test.status == 0) {
			withAnimation {
				contents.removeAll { $0.url == url }
			}
		} else {
			errorString = test.output
			gotErrors = true
		}
	}
	
	private func filteredContents() -> [ContentItem] {
		if searchText.isEmpty {
			return contents
		} else {
			var result: [ContentItem] = []
			var text: String
			var range: NSRange
			let regex: NSRegularExpression = try! NSRegularExpression(pattern: searchText)

			for item in contents {
				text = item.url.lastPathComponent
				range = NSRange(location: 0, length: text.utf16.count)
				if regex.firstMatch(in: text, options: [], range: range) != nil {
					result.append(contentsOf: [item])
				}
			}

			return result
		}
	}
}

struct ContentItem: Identifiable {
    let id = UUID()
    let url: URL
    let isFolder: Bool
    let isSymbolicLink: Bool
    let fileSize: Int64
    let modificationDate: Date
	let realPath: String
	
	@AppStorage("useSize") var size: FileSizeOptions = .MegaByte
	@AppStorage("allowNonNumbericSize") var nonNumbericSize: Bool = true
    
    var fileSizeFormatted: String {
		let usedUnit: ByteCountFormatter.Units
		
		switch size {
		case .MegaByte:
			usedUnit = .useMB
		case .GigaByte:
			usedUnit = .useGB
		case .KiloByte:
			usedUnit = .useKB
		}
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [usedUnit]
        byteCountFormatter.countStyle = .file
		byteCountFormatter.allowsNonnumericFormatting = nonNumbericSize

        // If the file size is less than 1000 bytes, display it in bytes
        if fileSize < 1000 {
            byteCountFormatter.allowedUnits = [.useBytes]
            byteCountFormatter.countStyle = .file
        }

        return byteCountFormatter.string(fromByteCount: fileSize)
    }

	let childrens: [ContentItem]?
}

//sorting methods
enum SortOption: String, CaseIterable, Identifiable {
    case name = "Alphabet"
    case size = "Size"
    case modificationDate = "Modification Date"
	
	case name_reserve = "Zphabet"
	case size_reserve = "Size (largest first)"
	case modificationDateLastFirst = "Last modified"

    var id: String { self.rawValue }

    func sortingComparator(_ item1: ContentItem, _ item2: ContentItem) -> Bool {
        switch self {
        case .name:
            return item1.url.lastPathComponent.localizedCaseInsensitiveCompare(item2.url.lastPathComponent) == .orderedAscending
        case .size:
            return item1.fileSize < item2.fileSize
        case .modificationDate:
            return item1.modificationDate < item2.modificationDate
		case .name_reserve:
			return item1.url.lastPathComponent.localizedCaseInsensitiveCompare(item2.url.lastPathComponent) == .orderedDescending
		case .size_reserve:
			return item1.fileSize > item2.fileSize
		case .modificationDateLastFirst:
			return item1.modificationDate > item2.modificationDate
        }
    }
	
	func sortingComparatorStr(_ str1: String, _ str2: String) -> Bool {
		switch self {
		case .name_reserve:
			return str1.localizedCaseInsensitiveCompare(str2) == .orderedDescending
		default:
			return str1.localizedCaseInsensitiveCompare(str2) == .orderedAscending
		}
	}
}

struct ContentView: View {
	@State private var input: String = (UserDefaults.standard.string(forKey: "defaultPath") ?? "/var")
	@State private var settingsCalled: Bool = false
	
	@AppStorage("homePageSortBy") var sortBy: SortOption = .name
	@AppStorage("favourites") var favourites: [String] = []
	@AppStorage("queueMove") var moveList: [String] = []
	@AppStorage("queueCopy") var copyList: [String] = []
	@AppStorage("queueCut") var cutList: [String] = []

	var body: some View {
		List {
			Text("Favourites").font(.title3.bold())
			
			ForEach(favourites.sorted(by: sortBy.sortingComparatorStr), id:\.self) {item in
				Text(item)
			}
			.onDelete { favourites.remove(atOffsets: $0) }
			
			Text("Move Queue").font(.title3.bold())
			ForEach(moveList.sorted(by: sortBy.sortingComparatorStr), id:\.self) {item in
				Text(item)
			}
			.onDelete { moveList.remove(atOffsets: $0) }
			
			Text("Copy Queue").font(.title3.bold())
			ForEach(copyList.sorted(by: sortBy.sortingComparatorStr), id:\.self) {item in
				Text(item)
			}
			.onDelete { copyList.remove(atOffsets: $0) }
			
			Text("Cut Queue").font(.title3.bold())
					
			ForEach(cutList.sorted(by: sortBy.sortingComparatorStr), id:\.self) {item in
				Text(item)
			}
			.onDelete { cutList.remove(atOffsets: $0) }
					
			TextField("", text: $input, prompt: Text("Where do you want to go today?"))
	
			NavigationLink {
				DirListView(folderURL: URL(fileURLWithPath: input))
			} label: {
				Text("Go")
			}
		}
		.navigationBarTitle("Home")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				HStack {
					Picker("", selection: $sortBy, content: {
						ForEach(SortOption.allCases, id: \.self) { option in
							Text(option.rawValue).tag(option)
						}
					})
					.pickerStyle(MenuPickerStyle())
					
					Button("Settings", systemImage: "gear", action: { settingsCalled = true })
						.labelStyle(.iconOnly)
					
					EditButton()
				}
			}
		}
		.sheet(isPresented: $settingsCalled) {
			SettingsView(isPresented: $settingsCalled)
				.navigationBarTitle("Settings")
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
}
