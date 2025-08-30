//
//  AddableListReducer.swift
//  Wordbook
//
//  Created by Elliot Schrock on 3/13/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AddableListReducer {
    @Dependency(\.watchConnectivityClient) var watchClient
    
    @ObservableState
    struct State: Equatable {
        var allPhrases: IdentifiedArrayOf<Phrase> = .init()
        var displayedPhrases: IdentifiedArrayOf<Phrase> = .init()
        var localFilter = ""
        var sortScheme: SortScheme = .recent
        
        @Presents var new: EditPhraseReducer.State?
        @Presents var edit: EditPhraseReducer.State?
        @Presents var details: PhraseReducer.State?
        
        var phraseToItemState: (Phrase) -> PhraseReducer.State
        var phraseToSearchableString: ((Phrase) -> String)?
        
        static func == (lhs: AddableListReducer.State, rhs: AddableListReducer.State) -> Bool {
            return lhs.allPhrases == rhs.allPhrases
            && lhs.displayedPhrases == rhs.displayedPhrases
            && lhs.localFilter == rhs.localFilter
            && lhs.details == rhs.details
            && lhs.new == rhs.new
            && lhs.edit == rhs.edit
        }
        
        public init(data: [Phrase] = loadData(),
                    phraseToItemState: @escaping (Phrase) -> PhraseReducer.State,
                    phraseToSearchableString: ((Phrase) -> String)?
        ) {
            var phraseSet = Set<Phrase>()
            data.forEach { if !phraseSet.contains($0) { phraseSet.insert($0) } }
            self.allPhrases = IdentifiedArray(uniqueElements: Array(phraseSet).filter { !$0.id.isEmpty })
            self.displayedPhrases = IdentifiedArray(uniqueElements: Array(phraseSet).filter { !$0.id.isEmpty }.sorted(by: { $0.createdAt > $1.createdAt }))
            self.phraseToItemState = phraseToItemState
            self.phraseToSearchableString = phraseToSearchableString
        }
    }
    
    enum SortScheme: Equatable {
        case recent, alphabet
    }
    
    enum Action: BindableAction {
        case addNewTapped
        case saveNew, cancel
        case saveEdit
        case editPhrase(id: String)
        case didAppear
        case didChangeScenePhase
        case didShowPhraseIndex(Int)
        case dataNeedsReload
        case removePhrase(id: String)
        case shuffle
        case sortByRecent
        case sortByAlphabet
        
        case binding(BindingAction<State>)
        case phrase(Phrase.ID, PhraseReducer.Action)
        case add(PresentationAction<EditPhraseReducer.Action>)
        case edit(PresentationAction<EditPhraseReducer.Action>)
        case details(PresentationAction<PhraseReducer.Action>)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.localFilter) { oldValue, newValue in
                Reduce { state, action in
                    state.displayedPhrases = displayable(from: state.allPhrases, state.localFilter, state.sortScheme, state.phraseToSearchableString)
                    return .none
                }
            }
        Reduce { state, action in
            switch action {
            case .addNewTapped: 
                state.new = EditPhraseReducer.State()
            case .saveNew:
                let phrase = Phrase(id: state.new?.text ?? "", translation: state.new?.translation ?? "", createdAt: Date())
                var data = state.allPhrases
                data.insert(phrase, at: 0)
                state.allPhrases = data
                state.displayedPhrases = displayable(from: state.allPhrases, state.localFilter, state.sortScheme, state.phraseToSearchableString)
                save(data.elements)
                
                state.new = nil
                
            case .saveEdit:
                if let phrase = state.edit?.phrase {
                    let newPhrase = Phrase(id: state.edit?.text ?? phrase.id, translation: state.edit?.translation ?? phrase.translation, createdAt: phrase.createdAt)
                    var data = state.allPhrases
                    if let index = data.firstIndex(of: phrase) {
                        data.remove(at: index)
                        data.insert(newPhrase, at: index)
                    } else {
                        data.insert(newPhrase, at: 0)
                    }
                    state.allPhrases = data
                    save(data.elements)
                }
                state.edit = nil
            case .cancel:
                state.new = nil
                state.edit = nil
                return .none
            case .didAppear, .didChangeScenePhase:
                return .run { send in
                    await self.onTask(send: send)
                }
            case .didShowPhraseIndex(let index): break
            case let .editPhrase(id: id):
                if let phrase = state.allPhrases.first(where: { $0.id == id }) {
                    state.edit = EditPhraseReducer.State(phrase: phrase)
                }
            case .phrase(_, _): break
            case .binding(_): break
            case .add(_): break
            case .edit(_): break
            case .details(_): break
                
            case .dataNeedsReload:
                let data = loadData()
                state.allPhrases = IdentifiedArray(uniqueElements: data)
                
            case .removePhrase(id: let id):
                var data = state.allPhrases
                if let index = data.firstIndex(where: { $0.id == id }) {
                    data.remove(at: index)
                }
                state.allPhrases = data
                save(data.elements)
                
            case .shuffle: break
                
            case .sortByRecent:
                state.sortScheme = .recent
                var displayedPhrases = state.allPhrases
                if let searchableStringFrom = state.phraseToSearchableString {
                    if !state.localFilter.isEmpty {
                        displayedPhrases = state.allPhrases.filter({ phrase in
                            return matchesWordsPrefixes(state.localFilter, searchableStringFrom(phrase))
                        })
                    }
                }
                switch state.sortScheme {
                case .alphabet:
                    displayedPhrases = IdentifiedArray(uniqueElements: displayedPhrases.sorted(by: { $0.id < $1.id }))
                case .recent:
                    displayedPhrases = IdentifiedArray(uniqueElements: displayedPhrases.sorted(by: { $0.createdAt > $1.createdAt }))
                }
                state.displayedPhrases = displayedPhrases

            case .sortByAlphabet:
                state.sortScheme = .alphabet
                var displayedPhrases = state.allPhrases
                if let searchableStringFrom = state.phraseToSearchableString {
                    if !state.localFilter.isEmpty {
                        displayedPhrases = state.allPhrases.filter({ phrase in
                            return matchesWordsPrefixes(state.localFilter, searchableStringFrom(phrase))
                        })
                    }
                }
                switch state.sortScheme {
                case .alphabet:
                    displayedPhrases = IdentifiedArray(uniqueElements: displayedPhrases.sorted(by: { $0.id < $1.id }))
                case .recent:
                    displayedPhrases = IdentifiedArray(uniqueElements: displayedPhrases.sorted(by: { $0.createdAt > $1.createdAt }))
                }
                state.displayedPhrases = displayedPhrases
            }
            return .none
        }
        .ifLet(\.$new, action: \.add) {
            EditPhraseReducer()
        }
        .ifLet(\.$edit, action: \.edit) {
            EditPhraseReducer()
        }
        .ifLet(\.$details, action: \.details) {
            PhraseReducer()
        }
//        .forEach(\.allPhrases, action: /Action.phrase(_:_:)) {
//            PhraseReducer()
//        }
        Reduce { state, action in
            switch action {
            case .didAppear, .saveNew, .saveEdit:
                watchClient.session.sendMessage(["phrases": try? JSONEncoder().encode(state.allPhrases)], replyHandler: { _ in
                    print("reply")
                })
            default: break
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
    
    private func displayable(from allPhrases: IdentifiedArrayOf<Phrase>, _ localFilter: String, _ sortScheme: SortScheme, _ stringConverter: ((Phrase) -> String)?) -> IdentifiedArrayOf<Phrase> {
        var displayedPhrases = allPhrases
        if let searchableStringFrom = stringConverter {
            if !localFilter.isEmpty {
                displayedPhrases = allPhrases.filter({ phrase in
                    return matchesWordsPrefixes(localFilter, searchableStringFrom(phrase))
                })
            }
        }
        switch sortScheme {
        case .alphabet:
            displayedPhrases = IdentifiedArray(uniqueElements: displayedPhrases.sorted(by: { $0.id < $1.id }))
        case .recent:
            displayedPhrases = IdentifiedArray(uniqueElements: displayedPhrases.sorted(by: { $0.createdAt > $1.createdAt }))
        }
        return displayedPhrases
    }
}

func matchesWordsPrefixes(_ search: String, _ text: String) -> Bool {
    let textWords = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
    let searchWords = search.components(separatedBy: CharacterSet.alphanumerics.inverted)
    for word in searchWords {
        var foundMatch = false
        for textWord in textWords {
            if textWord.prefix(word.count).caseInsensitiveCompare(word) == .orderedSame {
                foundMatch = true
                break
            }
        }
        if !foundMatch {
            return false
        }
    }
    return true
}
