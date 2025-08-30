import Foundation
import ComposableArchitecture

@Reducer
struct SplashReducer {
    @ObservableState
    struct State: Equatable {
        @Presents var login: LoginReducer.State?
        @Presents var landing: LandingReducer.State?
        @Presents var reset: ResetPasswordReducer.State?
        @Presents var authed: AddableListReducer.State?
    }
    
    enum Action {
        case login(PresentationAction<LoginReducer.Action>)
        case landing(PresentationAction<LandingReducer.Action>)
        case reset(PresentationAction<ResetPasswordReducer.Action>)
        case authed(PresentationAction<AddableListReducer.Action>)
        case didAppear
        case advanceAuthed
        case advanceUnauthed
    }
    
    @Dependency(\.mainQueue) public var mainQueue
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didAppear:
                if let _ = UserDefaults.standard.data(forKey: "apiKey") {
                    return .run { send in
                        try await self.mainQueue.sleep(for: .seconds(1))
                        await send(.advanceAuthed)
                    }
                } else {
                    return .run { send in
                        try await self.mainQueue.sleep(for: .seconds(1))
                        await send(.advanceUnauthed)
                    }
                }
            case .advanceAuthed:
                state.authed = AddableListReducer.State(phraseToItemState: { $0 },                                                                                    phraseToSearchableString: { "\($0.id) \($0.translation ?? "")" })
            case .advanceUnauthed:
                state.landing = .init()
            case .landing(.presented(.login(.presented(.delegate(.advanceAuthed))))), 
                    .landing(.presented(.signUp(.presented(.delegate(.advanceAuthed))))):
                state.login = nil
                state.landing = nil
                state.reset = nil
                state.authed = AddableListReducer.State(phraseToItemState: { $0 },
                                                        phraseToSearchableString: { "\($0.id) \($0.translation ?? "")" })
            case .login(_): break
            case .landing(_): break
            case .reset(_): break
            case .authed(_): break
            }
            return .none
        }.ifLet(\.$login, action: \.login) {
            LoginReducer()
        }.ifLet(\.$landing, action: \.landing) {
            LandingReducer()
        }.ifLet(\.$reset, action: \.reset) {
            ResetPasswordReducer()
        }.ifLet(\.$authed, action: \.authed) {
            AddableListReducer()
        }
    }
}
