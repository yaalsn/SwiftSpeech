//
//  Extensions.swift
//  
//
//  Created by Cay Zhang on 2020/2/16.
//

import SwiftUI
import Combine
import Speech

public extension View {
    func onStartRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
    ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        self.transformEnvironment(\.actionsOnStartRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
    
    func onStopRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
    ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        self.transformEnvironment(\.actionsOnStopRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
    
    func onCancelRecording(appendAction actionToAppend: @escaping (_ session: SwiftSpeech.Session) -> Void) ->
    ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(_ session: SwiftSpeech.Session) -> Void]>> {
        self.transformEnvironment(\.actionsOnCancelRecording) { actions in
            actions.insert(actionToAppend, at: 0)
        } as! ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>>
    }
}

public extension View {
    func onStartRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        self.onStartRecording { session in
            subject.send(session)
        }
    }
    
    func onStartRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        self.onStartRecording { session in
            subject.send(session)
        }
    }
    
    func onStopRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        self.onStopRecording { session in
            subject.send(session)
        }
    }
    
    func onStopRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        self.onStopRecording { session in
            subject.send(session)
        }
    }
    
    func onCancelRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session {
        self.onCancelRecording { session in
            subject.send(session)
        }
    }
    
    func onCancelRecording<S: Subject>(sendSessionTo subject: S) -> ModifiedContent<Self, _EnvironmentKeyTransformModifier<[(SwiftSpeech.Session) -> Void]>> where S.Output == SwiftSpeech.Session? {
        self.onCancelRecording { session in
            subject.send(session)
        }
    }
}

public extension View {
    
    func swiftSpeechRecordOnHold(
        locale: Locale = .autoupdatingCurrent,
        animation: Animation = SwiftSpeech.defaultAnimation,
        distanceToCancel: CGFloat = 50.0
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.RecordOnHold> {
        self.modifier(
            SwiftSpeech.ViewModifiers.RecordOnHold(
                locale: locale,
                animation: animation,
                distanceToCancel: distanceToCancel
            )
        )
    }
    
    func swiftSpeechToggleRecordingOnTap(
        locale: Locale = .autoupdatingCurrent,
        animation: Animation = SwiftSpeech.defaultAnimation
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.ToggleRecordingOnTap> {
        self.modifier(SwiftSpeech.ViewModifiers.ToggleRecordingOnTap(locale: locale, animation: animation))
    }
    
    func onRecognize(
        includePartialResults isPartialResultIncluded: Bool = true,
        handleResult resultHandler: @escaping (SwiftSpeech.Session, SFSpeechRecognitionResult) -> Void,
        handleError errorHandler: @escaping (SwiftSpeech.Session, Error) -> Void = { _, _ in }
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        modifier(
            SwiftSpeech.ViewModifiers.OnRecognize(
                isPartialResultIncluded: isPartialResultIncluded,
                resultHandler: resultHandler,
                errorHandler: errorHandler
            )
        )
    }
    
    func onRecognize(
        includePartialResults isPartialResultIncluded: Bool = true,
        handleResult resultHandler: @escaping (SFSpeechRecognitionResult) -> Void,
        handleError errorHandler: @escaping (Error) -> Void = { _ in }
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        onRecognize(
            includePartialResults: isPartialResultIncluded,
            handleResult: { _, result in resultHandler(result) },
            handleError: { _, error in errorHandler(error) }
        )
    }
    
    func onRecognize(
        includePartialResults isPartialResultIncluded: Bool = true,
        update textBinding: Binding<String>
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        self.onRecognize(includePartialResults: isPartialResultIncluded) { result in
            textBinding.wrappedValue = result.bestTranscription.formattedString
        } handleError: { _ in }
    }
    
    func printRecognizedText(
        includePartialResults isPartialResultIncluded: Bool = true
    ) -> ModifiedContent<Self, SwiftSpeech.ViewModifiers.OnRecognize> {
        self.onRecognize(includePartialResults: isPartialResultIncluded) { result in
            print("[SwiftSpeech] Recognized Text: \(result.bestTranscription.formattedString)")
        } handleError: { _ in }
    }
}

public extension Subject where Output == SpeechRecognizer.ID?, Failure == Never {
    
    func mapResolved<T>(_ transform: @escaping (SpeechRecognizer) -> T) -> Publishers.CompactMap<Self, T> {
        return self
            .compactMap { (id) -> T? in
                if let recognizer = SpeechRecognizer.recognizer(withID: id) {
                    return transform(recognizer)
                } else {
                    return nil
                }
            }
    }
    
    func mapResolved<T>(_ keyPath: KeyPath<SpeechRecognizer, T>) -> Publishers.CompactMap<Self, T> {
        return self
            .compactMap { (id) -> T? in
                if let recognizer = SpeechRecognizer.recognizer(withID: id) {
                    return recognizer[keyPath: keyPath]
                } else {
                    return nil
                }
            }
    }
    
}

public extension SwiftSpeech {
    static func supportedLocales() -> Set<Locale> {
        SFSpeechRecognizer.supportedLocales()
    }
}
