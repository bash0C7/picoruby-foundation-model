reason = FoundationModel._availability_reason
if reason
  puts "Apple Intelligence unavailable: #{reason}"
else
  puts FoundationModel.generate("Write a haiku about Ruby.")
end
