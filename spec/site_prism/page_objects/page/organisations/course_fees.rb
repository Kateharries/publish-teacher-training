module PageObjects
  module Page
    module Organisations
      class CourseFees < PageObjects::Base
        set_url '/organisations/{provider_code}/courses/{course_code}/fees'

        element :title, '.govuk-heading-xl'
        element :caption, '.govuk-caption-xl'
        element :course_length_one_year, '#course_course_length_oneyear'
        element :course_length_two_years, '#course_course_length_twoyears'
        element :course_fees_uk, '#course_fee_uk_eu'
        element :course_fees_international, '#course_fee_international'
        element :fee_details, '#course_fee_details'
        element :financial_support, '#course_financial_support'
      end
    end
  end
end