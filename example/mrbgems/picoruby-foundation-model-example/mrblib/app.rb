reason = FoundationModel._availability_reason
if reason
  puts "Apple Intelligence unavailable: #{reason}"
else
  prompt = "Write a haiku about Ruby."
  puts "Prompt:   #{prompt}"
  puts "Response: #{FoundationModel.generate(prompt)}"

  session = FoundationModel::Session.new(instructions: "Always answer in Japanese, in one short sentence.")
  puts "Turn 1:   #{session.respond("My favorite color is green. Please remember it.")}"
  puts "Turn 2:   #{session.respond("What is my favorite color?")}"
  begin
    session.respond("Write a long story about a robot.", timeout_ms: 100)
  rescue FoundationModel::TimeoutError => e
    puts "Timeout:  #{e.message}"
  end
  puts "Turn 3:   #{session.respond("What is my favorite color?", timeout_ms: 30000)}"
end
