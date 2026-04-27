//
//  SpeechClient.swift
//  WBLib
//
//  Created by Elliot Schrock on 9/21/23.
//

#if canImport(Speech)
@preconcurrency import Speech
#endif
import Dependencies

// All languages Apple's Translation framework currently pairs with English
// for on-device translation. BCP-47 identifiers chosen so SFSpeechRecognizer
// also accepts them (region-qualified locales).
enum Language: String, Codable, CaseIterable, Equatable {
    case english = "en-US"
    case arabic = "ar-SA"
    case chineseSimplified = "zh-CN"
    case chineseTraditional = "zh-TW"
    case dutch = "nl-NL"
    case french = "fr-FR"
    case german = "de-DE"
    case hindi = "hi-IN"
    case indonesian = "id-ID"
    case italian = "it-IT"
    case japanese = "ja-JP"
    case korean = "ko-KR"
    case polish = "pl-PL"
    case portugueseBrazil = "pt-BR"
    case russian = "ru-RU"
    case spanish = "es-ES"
    case thai = "th-TH"
    case turkish = "tr-TR"
    case ukrainian = "uk-UA"
    case vietnamese = "vi-VN"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "Arabic"
        case .chineseSimplified: return "Chinese (Simplified)"
        case .chineseTraditional: return "Chinese (Traditional)"
        case .dutch: return "Dutch"
        case .french: return "French"
        case .german: return "German"
        case .hindi: return "Hindi"
        case .indonesian: return "Indonesian"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .polish: return "Polish"
        case .portugueseBrazil: return "Portuguese (Brazil)"
        case .russian: return "Russian"
        case .spanish: return "Spanish"
        case .thai: return "Thai"
        case .turkish: return "Turkish"
        case .ukrainian: return "Ukrainian"
        case .vietnamese: return "Vietnamese"
        }
    }
}

@available(iOS 15.0, *)
struct SpeechClient {
    static var language: Language = .english
    var requestAuthorization: @Sendable () async -> Int
    var start: @Sendable () -> AsyncThrowingStream<String, Error>
}

extension SpeechClient: DependencyKey {
    static let liveValue = Self(
        requestAuthorization: {
            await withUnsafeContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(with: .success(status.rawValue))
                }
            }
        },
        start: {
            AsyncThrowingStream { continuation in
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                
                let audioEngine = AVAudioEngine()
                let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language.rawValue))!
                let request = SFSpeechAudioBufferRecognitionRequest()
                let recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                    switch (result, error) {
                    case let (.some(result), _):
                        continuation.yield(result.bestTranscription.formattedString)
                    case (_, .some):
                        continuation.finish(throwing: error)
                    case (.none, .none):
                        fatalError("It should not be possible to have both a nil result and nil error.")
                    }
                }
                
                continuation.onTermination = { [audioEngine, recognitionTask] _ in
                    _ = speechRecognizer
                    audioEngine.stop()
                    audioEngine.inputNode.removeTap(onBus: 0)
                    recognitionTask.finish()
                }
                
                audioEngine.inputNode.installTap(
                    onBus: 0,
                    bufferSize: 1024,
                    format: audioEngine.inputNode.outputFormat(forBus: 0)
                ) { buffer, when in
                    request.append(buffer)
                }
                
                audioEngine.prepare()
                do {
                    try audioEngine.start()
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
            }
        }
    )
    
    static let previewValue = SpeechClient(
        requestAuthorization: { 3 }, // .authorized
        start: {
            AsyncThrowingStream { continuation in
                Task { @MainActor in
                    var finalText = SpeechClient.language == .english ? "a series of mistakes" : "eine reihe von fehlen"
                    var text = ""
                    while true {
                        let word = finalText.prefix { $0 != " " }
                        try await Task.sleep(for: .milliseconds(word.count * 50 + .random(in: 0...200)))
                        finalText.removeFirst(word.count)
                        if finalText.first == " " {
                            finalText.removeFirst()
                        }
                        text += word + " "
                        continuation.yield(text)
                    }
                }
            }
        }
    )
}

extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}
