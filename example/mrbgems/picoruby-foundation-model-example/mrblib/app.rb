reason = FoundationModel._availability_reason
if reason
  puts "Apple Intelligence unavailable: #{reason}"
else
  prompt = "Write a haiku about Ruby."
  puts "Prompt:   #{prompt}"
  puts "Response: #{FoundationModel.generate(prompt)}"
end
