local Translations = {
    error = {
        not_in_range = 'Too far from the city hall'
    },
    success = {
        recived_license = 'You have recived your %{value} for $50'
    },
    info = {
        bilp_text = 'City Services',
        city_services_menu = '~g~E~w~ - City Services Menu',
        id_card = 'ID Card',
        driver_license = 'Drivers License',
        weaponlicense = 'Firearms License',
        new_job = 'Congratulations with your new job! (%{job})'
    },
    email = {
        mr = 'Mr',
        mrs = 'Mrs',
        sender = 'Township',
        subject = 'Driving lessons request',
        message = 'Hello %{gender} %{lastname}<br /><br />We have just received a message that someone wants to take driving lessons<br />If you are willing to teach, please contact us:<br />Name: <strong>%{firstname} %{lastname}</strong><br />Phone Number: <strong>%{phone}</strong><br/><br/>Kind regards,<br />Township Los Santos'
    },
    menu = {
        identity_menu_title = 'Identity',
        identity_menu_desc = 'Obtain a drivers license or ID card',
        employment_menu_title = 'Employment',
        employment_menu_desc = 'Select a new job',
        price = 'Price',
        open_cityhalltitle = '[E] Open Cityhall',
        open_schooltitle = '[E] Take Driving Lessons',
        cityhalllabel = 'City Hall'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
