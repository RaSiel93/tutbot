require './antigate_api.rb'
require './info.rb'
require './second_names.rb'
require './first_names_array_men.rb'
require './first_names_array_women.rb'
require 'capybara/dsl'
require 'logger'
require 'translit'
require 'unicode'
require 'RMagick'
include Magick
include Capybara::DSL 
Capybara.default_driver = :selenium

logger = Logger.new("logfile.log")

if not ARGV[0].to_i > 0
	logger.error("bad parameter: " + ARGV[0].to_s)
	exit
end

number = ARGV[0].to_i
logger.info("run with parameter: " + number.to_s)

for number_iteration in 0..number do
	visit "http://profile.tut.by/"
	page.click_button "Я согласен с правилами"

	sex = rand(2) + 1

	first_name = nil
	if sex == 2
		first_name = @first_names_array_women[rand(301)]
	else
		first_name = @first_names_array_men[rand(387)]
	end

	second_name = @second_names_array[rand(200)]
	if sex == 2
		second_name += "a"
	end

	username = Translit.convert(first_name + second_name).sub('\'', "").sub(" ","")
		
	while true
		
		#username = [*('a'..'z')].sample(10).join
		puts username
		fill_in('Username', :with => username)
		page.click_button "Проверить" 
		if page.find('div#idCheckFreeMessage').text == 'Идентификатор пользователя свободен'
			break
		end
		username += "1"
		logger.warn("username is not free")
	end
	logger.info("username is free")

	password = (0...8).map{ ('a'..'z').to_a[rand(26)] }.join
	fill_in('Password1', :with => password)
	fill_in('Password2', :with => password)
	logger.info("password is entered")

	answer = [*('a'..'z')].sample(10).join
	fill_in('Answer', :with => answer)
	logger.info("answer is entered")

	
	fill_in('FirstName', :with => first_name)
	logger.info("first_name is entered")

	
	fill_in('SecondName', :with => second_name)
	logger.info("second_name  is entered")

	day_birthday = rand(27) + 1
	fill_in('_3_1', :with => day_birthday)
	logger.info("day birthday is entered")

	month_birthday = rand(12) + 1

	within ('select#_3_2') do
		first(:xpath, 'option[@value="' + month_birthday.to_s + '"]').select_option	  
	end
	logger.info("month birthday is entered")

	year_birthday = 1960 + rand(50)
	fill_in('_3_3', :with => year_birthday)
	logger.info("year birthday is entered")

	within ('select#_4') do
		first(:xpath, 'option[@value="' + sex.to_s + '"]').select_option
	end
	logger.info("sex is select")

	page.driver.browser.save_screenshot @path_to_screenshot
	logger.info("screenshot save in " + @path_to_screenshot)


	screenshot = ImageList.new(@path_to_screenshot)
	captcha = screenshot.crop(479, 1305, 290, 80)
	captcha.write(@path_to_captcha)
	logger.info("captcha save in " + @path_to_captcha)

	limit = 0
	while true
		captcha_id = send_captcha(@key, @path_to_captcha)
		if captcha_id != 'OR_NO_SLOT_AVAILABLE'
			break
		elsif limit > 60 
			logger.error("service is busy")
			exit
		end
		limit += 1
		logger.warn("id: " + captcha_id)
	end
	logger.info("captcha id obtained: " + captcha_id)

	sleep(@recognition_time)

	limit = 0
	while true
		captcha_text = get_captcha_text(@key, captcha_id)
		if captcha_text != nil
			break
		elsif limit > 30 
			logger.error("service not work")
			exit
		end
		limit += 1
		logger.warn("not_result_captcha: " + captcha_text.to_s)
		sleep 5
	end

	logger.info("captcha text obtained: " + captcha_text.to_s)
	fill_in('ap_word', :with => Unicode::downcase(captcha_text.force_encoding('UTF-8')))
	logger.info("captcha text is entered")

	uncheck('_14')
	uncheck('bonusSub')
	uncheck('iTUT')

	page.click_button "Зарегистрироваться"
	if page.has_selector?('div#idCodeMessage')
		report_bad( @key, @captcha_id)
		logger.error("bad captcha")
		number_iteration -= 1
	else
		logger.info("user is logged")
	end
	Capybara.reset_sessions!
end