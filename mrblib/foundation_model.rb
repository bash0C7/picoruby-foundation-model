module FoundationModel
  class UnavailableError < StandardError; end

  # Fail fast if Apple Intelligence is not available, then send the prompt to
  # the on-device model and return its reply as a String.
  def self.generate(prompt)
    reason = _availability_reason
    unless reason.nil?
      raise UnavailableError, "Apple Intelligence unavailable: #{reason}"
    end
    _generate(prompt)
  end
end
