//
//  SplashReducer.swift
//  Wordbook
//
//  Created by Elliot Schrock on 11/20/23.
//

import Foundation
import ComposableArchitecture

public struct SplashReducer: Reducer {
    public struct State {
        
    }
    
    public enum Action {
        
        public enum Delegate {
            case advanceAuthed, advanceUnauthed
        }
    }
    
    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            }
            return .none
        }
    }
}

//import ComposableArchitecture
//
//public struct SplashReducer: Reducer {
//    public struct State {
//        
//    }
//    
//    public enum Action {
//        
//    }
//    
//    public var body: some Reducer<State, Action> {
//        Reduce { state, action in
//            switch action {
//                
//            }
//            return .none
//        }
//    }
//}
