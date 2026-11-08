module FoundationModel
  class UnavailableError < StandardError; end
  class GenerationError < RuntimeError; end
  class TimeoutError < GenerationError; end

  def self.ensure_available
    reason = _availability_reason
    unless reason.nil?
      raise UnavailableError, "Apple Intelligence unavailable: #{reason}"
    end
  end

  # Fail fast if Apple Intelligence is not available, then send the prompt to
  # the on-device model and return its reply as a String.
  def self.generate(prompt)
    ensure_available
    _generate(prompt)
  end

  class Session
    def initialize(instructions: nil)
      FoundationModel.ensure_available
      _open(instructions)
    end

    def respond(prompt, timeout_ms: nil)
      _respond(prompt, timeout_ms || 0)
    end
  end
end
