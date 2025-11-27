//
//  WorterbuchListReducer.swift
//  Template
//
//  Created by Elliot Schrock on 4/18/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct WorterbuchListReducer {
    
    @ObservableState
    struct State: Equatable {
        var allWorterbuchs: IdentifiedArrayOf<Worterbuch> = .init()
        var displayedWorterbuchStates: IdentifiedArrayOf<WorterbuchItemReducer.State> {
            var displayedWorterbuchs = allWorterbuchs
            if let searchableStringFrom = worterbuchToSearchableString {
                if !localFilter.isEmpty {
                    displayedWorterbuchs = allWorterbuchs.filter({ worterbuch in
                        return matchesWordsPrefixes(localFilter, searchableStringFrom(worterbuch))
                    })
                }
            }
            return IdentifiedArray(uniqueElements: displayedWorterbuchs.map { worterbuchToItemState($0) })
        }
        var localFilter = ""
        @Presents var new: EditWorterbuchReducer.State?
        @Presents var edit: EditWorterbuchReducer.State?
        @Presents var details: AddableListReducer.State?
        
        var worterbuchToItemState: (Worterbuch) -> WorterbuchItemReducer.State
        var worterbuchToSearchableString: ((Worterbuch) -> String)?
        
        static func == (lhs: WorterbuchListReducer.State, rhs: WorterbuchListReducer.State) -> Bool {
            return lhs.allWorterbuchs == rhs.allWorterbuchs
            && lhs.localFilter == rhs.localFilter
            && lhs.details == rhs.details
            && lhs.new == rhs.new
            && lhs.edit == rhs.edit
        }
        
        init(allWorterbuchs: IdentifiedArrayOf<Worterbuch> = .init(), localFilter: String = "", new: EditWorterbuchReducer.State? = nil, edit: EditWorterbuchReducer.State? = nil, details: AddableListReducer.State? = nil, worterbuchToItemState: @escaping (Worterbuch) -> WorterbuchItemReducer.State, worterbuchToSearchableString: ( (Worterbuch) -> String)? = nil) {
            self.allWorterbuchs = allWorterbuchs
            self.localFilter = localFilter
            self.new = new
            self.edit = edit
            self.details = details
            self.worterbuchToItemState = worterbuchToItemState
            self.worterbuchToSearchableString = worterbuchToSearchableString
        }
    }
    
    enum Action: BindableAction {
        case addNewTapped
        case didChangeScenePhase
        
        case binding(BindingAction<State>)
        case worterbuch(WorterbuchItemReducer.State.ID, WorterbuchItemReducer.Action)
        case edit(PresentationAction<EditWorterbuchReducer.Action>)
        case details(PresentationAction<AddableListReducer.Action>)
    }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addNewTapped: break
//                state.new = EditReducer.State()
            case .didChangeScenePhase:
                break
            case let .worterbuch(id, action):
                if let buch = state.allWorterbuchs[id: id] {
                    switch action {
                    case .didTap:
                        state.details = AddableListReducer.State(data: loadData(buch.key), key: buch.key, phraseToItemState: { $0 },                                                                     phraseToSearchableString: { "\($0.id) \($0.translation)" })
                    }
                }
            case .binding(_): break
            case .edit(_): break
            case .details(_): break
            }
            return .none
        }
        .ifLet(\.$new, action: \.edit) {
            EditWorterbuchReducer()
        }
        .ifLet(\.$edit, action: \.edit) {
            EditWorterbuchReducer()
        }
        .ifLet(\.$details, action: \.details) {
            AddableListReducer()
        }
        /// not necessary unless item reducer edits the worterbuchs
//        .forEach(\.displayedWorterbuchStates, action: AddableListReducer.Action.worterbuch(_:_:)) {
//            ItemReducer()
//        }
    }
}
