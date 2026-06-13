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
    let p = String(cString: prompt)

    let sem = DispatchSemaphore(value: 0)
    let outBox = Box<Result<String, Error>?>(nil)
    Task {
        do {
            let r = try await session.respond(to: p)
            outBox.value = .success(r.content)
        } catch {
            outBox.value = .failure(error)
        }
        sem.signal()
    }
    sem.wait()

    switch outBox.value! {
    case .success(let txt):
        return strdup(txt)
    case .failure(let e):
        error_out.pointee = strdup("\(e)")
        return nil
    }
}
