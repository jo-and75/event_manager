puts 'Event Manager initialized!' 

contents = File.read('event_attendees.csv') 
# puts contents 

lines = FIle.readlines('event_attendees.csv') 
lines.each do |line| 
  puts line 
end