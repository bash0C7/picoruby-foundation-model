import Foundation
import FoundationModels

private final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

// Plain C ABI (Swift @c / SE-0495). The session lifecycle and the async→sync
// bridge live here so the mruby C glue stays pure value-marshalling. Callers
// must free() every non-nil char* returned.

@c
public func fmm_availability_check() -> UnsafeMutablePointer<CChar>? {
    switch SystemLanguageModel.default.availability {
    case .available:
        return nil
    case .unavailable(let reason):
        return strdup("\(reason)")
    }
}

private enum Outcome {
    case reply(String)
    case failure(String)
    case timedOut
}

private func respondBlocking(_ session: LanguageModelSession, _ prompt: String, _ timeoutMs: Int64) -> Outcome {
    let sem = DispatchSemaphore(value: 0)
    let outBox = Box<Result<String, Error>?>(nil)
    let task = Task {
        do {
            let r = try await session.respond(to: prompt)
            outBox.value = .success(r.content)
        } catch {
            outBox.value = .failure(error)
        }
        sem.signal()
    }
    if timeoutMs > 0 {
        if sem.wait(timeout: .now() + .milliseconds(Int(timeoutMs))) == .timedOut {
            task.cancel()
            sem.wait()
            return .timedOut
        }
    } else {
        sem.wait()
    }
    switch outBox.value! {
    case .success(let txt):
        return .reply(txt)
    case .failure(let e):
        return .failure("\(e)")
    }
}

// One-shot: open a transient session, send the prompt, return the reply.
// The session is a local released by ARC when this returns — no handle crosses
// the C boundary. On error, *error_out is set (strdup'd) and nil is returned.
@c
public func fmm_generate(
    _ prompt: UnsafePointer<CChar>,
    _ error_out: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
) -> UnsafeMutablePointer<CChar>? {
    error_out.pointee = nil
    let session = LanguageModelSession(model: SystemLanguageModel.default)
    switch respondBlocking(session, String(cString: prompt), 0) {
    case .reply(let txt):
        return strdup(txt)
    case .failure(let msg):
        error_out.pointee = strdup(msg)
        return nil
    case .timedOut:
        error_out.pointee = strdup("timed out")
        return nil
    }
}

private final class SessionHandle {
    let session: LanguageModelSession
    init(_ session: LanguageModelSession) { self.session = session }
}

@c
public func fmm_session_new(_ instructions: UnsafePointer<CChar>?) -> UnsafeMutableRawPointer {
    let text = instructions.map { String(cString: $0) }
    let session = LanguageModelSession(model: SystemLanguageModel.default, instructions: text)
    return Unmanaged.passRetained(SessionHandle(session)).toOpaque()
}

@c
public func fmm_session_free(_ handle: UnsafeMutableRawPointer) {
    Unmanaged<SessionHandle>.fromOpaque(handle).release()
}

@c
public func fmm_session_respond(
    _ handle: UnsafeMutableRawPointer,
    _ prompt: UnsafePointer<CChar>,
    _ timeout_ms: Int64,
    _ text_out: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
) -> Int32 {
    text_out.pointee = nil
    let session = Unmanaged<SessionHandle>.fromOpaque(handle).takeUnretainedValue().session
    switch respondBlocking(session, String(cString: prompt), timeout_ms) {
    case .reply(let txt):
        text_out.pointee = strdup(txt)
        return 0
    case .failure(let msg):
        text_out.pointee = strdup(msg)
        return 1
    case .timedOut:
        return 2
    }
}
