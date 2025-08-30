//
//  PhraseListReducer.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

import Foundation
import ComposableArchitecture
import WatchConnectivity

public struct PhraseListReducer: Reducer {
    @Dependency(\.watchConnectivityClient) var watchClient
    
    public struct State: Equatable {
        public var data = [Phrase]() {
            didSet {
                sort(by: sortScheme)
            }
        }
        public var list = [Phrase]()
        var sortScheme: SortScheme = .recent
        
        public init(data: [Phrase] = loadData()) {
            self.data = data
            self.list = data.sorted(by: { $0.createdAt > $1.createdAt })
        }
        
        mutating func sort(by scheme: SortScheme) {
            sortScheme = scheme
            switch scheme {
            case .alphabet:
                list = data.sorted(by: { $0.id < $1.id })
            case .recent:
                list = data.sorted(by: { $0.createdAt > $1.createdAt })
            }
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case dataNeedsReload
        case addPhrase(Phrase)
        case removePhrase(id: String)
        case shuffle
        case sortByRecent
        case sortByAlphabet
    }
    
    enum SortScheme: Equatable {
        case recent, alphabet
    }
    
    public init() {}
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear, .dataNeedsReload, .addPhrase(_):
                watchClient.session.sendMessage(["phrases": try? JSONEncoder().encode(state.data)], replyHandler: { _ in
                    print("reply")
                })
            default: break
            }
            return .none
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await self.onTask(send: send)
                }
                
            case .dataNeedsReload:
                let data = loadData()
                state.data = data
                
            case .addPhrase(let phrase):
                var data = state.data
                data.insert(phrase, at: 0)
                state.data = data
                save(data)
                
            case .removePhrase(id: let id): break
//                state.list.remove(at: state.list.)
            case .shuffle: break
                
            case .sortByRecent:
                state.sort(by: .recent)
            case .sortByAlphabet:
                state.sort(by: .alphabet)
            }
            return .none
        }
    }
    
    private func onTask(send: Send<Action>) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    for try await message in self.watchClient.start() {
                        if let data = message["phrases"] as? Data, let phrases = try? JSONDecoder().decode([Phrase].self, from: data) {
                            saveUnique(phrases)
                            await send(.dataNeedsReload)
                        }
                    }
                } catch {
                    // TODO: Handle error
                }
            }
        }
    }
}

public func loadData() -> [Phrase] {
    if let data = UserDefaults.standard.data(forKey: "phrases"),
        let phrases = try? JSONDecoder().decode([Phrase].self, from: data) {
        return phrases
    }
    return []
}

func saveUnique(_ phrases: [Phrase]) {
    var data = loadData()
    data.append(contentsOf: phrases)
    let phraseSet = Set(data)
    let saveData = Array(phraseSet)
    save(saveData)
}

func save(_ phrases: [Phrase]) {
    try? UserDefaults.standard.set(JSONEncoder().encode(phrases), forKey: "phrases")
}
