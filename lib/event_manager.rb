require 'csv'
require 'google/apis/civicinfo_v2' 
require 'erb' 
require 'date'
 
civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(num)  
  num = num.include?('E') ? num.to_i : num.gsub(/[^0-9]/, '')

  case num.to_s.length
  when 10
    num
  when 11
    num.to_s.start_with?('1') ? num[1..-1] : 'Invalid number'
  else
    'Invalid number'
  end
end  

def get_time(date)
  time_obj = Time.strptime(date,'%m/%d/%y %H:%M') 
  hour_am_pm = time_obj.strftime('%I %p') 
end 

def get_day(date)  
  day_obj = Time.strptime(date,'%m/%d/%y %H:%M')
  day_of_the_week = day_obj.strftime("%A") 
  # puts day_of_the_week
end  

def optimal_days(days,top_n = 1) 
  frequency = days.tally

  top_days = frequency.max_by(top_n) { |_, count| count }

  top_days.each_with_index do |(day, count), index|
    puts "#{index + 1}: #{day} with #{count} registrations"
  end
end 

def optimal_time(hours, top_n = 1)
  # Calculate frequency of each time
  frequency = hours.tally

  # Find the top `top_n` times based on frequency
  top_times = frequency.max_by(top_n) { |_, count| count }

  # Print the top times
  top_times.each_with_index do |(time, count), index|
    puts "#{index + 1}: #{time} with #{count} registrations"
  end
end



def legislators_by_zipcode(zip) 
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end 

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end 

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

all_reg_times = [] 
all_reg_days = [] 

contents.each do |row| 
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_numbers = clean_phone_numbers(row[:homephone])  

  get_reg_time = (get_time(row[:regdate])) 

  days = get_day(row[:regdate]) 

  all_reg_times << get_reg_time 
  all_reg_days << days
 

  legislators = legislators_by_zipcode(zipcode) 

  form_letter = erb_template.result(binding) 

  save_thank_you_letter(id,form_letter)  

  puts phone_numbers
end

optimal_reg_time = optimal_time(all_reg_times,3) 
optimal_reg_days = optimal_days(all_reg_days,3)