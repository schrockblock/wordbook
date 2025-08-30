//
//  NetModelsReducer.swift
//  Template
//
//  Created by Elliot Schrock on 2/27/24.
//

import Foundation
import ComposableArchitecture
import FunNetCore
import FunNetTCA
import ErrorHandling

@Reducer
public struct NetModelsReducer<Model: Decodable & Equatable, Wrapper: Decodable> {
    @ObservableState
    public struct State: Equatable {
        public static func == (lhs: NetModelsReducer<Model, Wrapper>.State, rhs: NetModelsReducer<Model, Wrapper>.State) -> Bool {
            return lhs.models == rhs.models 
            && lhs.modelsCallState == rhs.modelsCallState
            && lhs.alert == rhs.alert
        }
        
        var models: [Model]
        var modelsCallState: NetCallReducer.State
        
        var unwrap: ((Wrapper) -> [Model]?)?
        
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    public enum Action: Equatable, BindableAction {
        case refresh
        case nextPage
        
        case binding(BindingAction<State>)
        
        case modelsCall(NetCallReducer.Action)
        
        case alert(PresentationAction<Alert>)
        public enum Alert: Equatable, Sendable {}
        
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case didUpdateModels([Model])
        }
    }
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.modelsCallState, action: /NetModelsReducer.Action.modelsCall, child: NetCallReducer.init)
        Reduce { state, action in
            switch action {
            case .refresh:
                return .send(.modelsCall(.refresh))
            case .nextPage:
                return .send(.modelsCall(.nextPage))
            case .modelsCall(.delegate(.responseData(let data))):
                if let unwrap = state.unwrap {
                    let wrapper = try! Current.apiJsonDecoder.decode(Wrapper.self, from: data)
                    if let models = unwrap(wrapper) {
                        if let pageInfo = state.modelsCallState.pagingInfo {
                            var updatedModels = [Model]()
                            let isNotFirstPage = state.modelsCallState.endpoint.isNotFirstPage(firstPageValue: pageInfo.firstPage, pageInfo.pageKey)
                            if isNotFirstPage {
                                updatedModels = state.models
                            }
                            updatedModels.append(contentsOf: models)
                            return .send(.delegate(.didUpdateModels(updatedModels)))
                        } else {
                            return .send(.delegate(.didUpdateModels(models)))
                        }
                    }
                } else if let models = try? Current.apiJsonDecoder.decode([Model].self, from: data) {
                    if let pageInfo = state.modelsCallState.pagingInfo {
                        var updatedModels = [Model]()
                        let isNotFirstPage = state.modelsCallState.endpoint.isNotFirstPage(firstPageValue: pageInfo.firstPage, pageInfo.pageKey)
                        if isNotFirstPage {
                            updatedModels = state.models
                        }
                        updatedModels.append(contentsOf: models)
                        return .send(.delegate(.didUpdateModels(updatedModels)))
                    } else {
                        return .send(.delegate(.didUpdateModels(models)))
                    }
                }
            case .modelsCall(.delegate(.error(let error as NSError))):
                var allErrors = urlLoadingErrorCodesDict
                allErrors.merge(urlResponseErrorMessages, uniquingKeysWith: { _, second in second })
                if let message = allErrors[error.code] {
                    state.alert = AlertState { TextState("Error: \(error.code)") } actions: {} message: {
                        TextState(message)
                    }
                }
            case .binding(_): break
            case .modelsCall(_): break
            case .alert(_): break
            case .delegate(_): break
            }
            return .none
        }
    }
}
