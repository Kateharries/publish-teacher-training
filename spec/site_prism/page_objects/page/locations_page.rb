module PageObjects
  module Page
    class LocationsPage < PageObjects::Base
      set_url '/organisations/{provider_code}/locations'

      element :title, 'h1'
      sections :locations, 'tbody tr' do
        element :link, 'a'
        element :cell, '[data-qa=provider__location-name]'
      end
      element :add_a_location_link, "a[href^=\"#{Settings.google_forms.add_location.url.gsub('?', '\?')}\"]"
    end
  end
end
