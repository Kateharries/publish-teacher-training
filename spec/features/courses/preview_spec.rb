require 'rails_helper'

feature 'Preview course', type: :feature do
  let(:course_jsonapi) do
    jsonapi(:course,
            name: 'English',
            provider: provider,
            accrediting_provider: accrediting_provider,
            course_length: 'OneYear',
            applications_open_from: '2019-01-01T00:00:00Z',
            start_date: '2019-09-01T00:00:00Z',
            fee_uk_eu: '9250.0',
            fee_international: '9250.0',
            fee_details: 'Optional fee details',
            has_scholarship_and_bursary?: true,
            scholarship_amount: '20000',
            bursary_amount: '22000',
            personal_qualities: 'We are looking for ambitious trainee teachers who are passionate and enthusiastic about their subject and have a desire to share that with young people of all abilities in this particular age range.',
            other_requirements: 'You will need three years of prior work experience, but not necessarily in an educational context.',
            about_accrediting_body: 'Something great about the accredited body',
            interview_process: 'Some helpful guidance about the interview process',
            has_vacancies?: true,
            site_statuses: [
              jsonapi_site_status('Running site with vacancies', :full_time, 'running'),
              jsonapi_site_status('Suspended site with vacancies', :full_time, 'suspended'),
              jsonapi_site_status('New site with vacancies', :full_time, 'new_status'),
              jsonapi_site_status('New site with no vacancies', :no_vacancies, 'new_status'),
              jsonapi_site_status('Running site with no vacancies', :no_vacancies, 'running')
            ])
  end

  let(:provider) {
    jsonapi(:provider,
            provider_code: 'AO',
            website: 'https://scitt.org',
            address1: '1 Long Rd',
            postcode: 'E1 ABC')
  }
  let(:accrediting_provider) { jsonapi(:provider) }
  let(:course)               { course_jsonapi.to_resource }
  let(:course_response)      { course_jsonapi.render }
  let(:decorated_course)     { course.decorate }

  before do
    stub_omniauth
    stub_api_v2_request(
      "/providers/AO/courses/#{course.course_code}?include=site_statuses.site,provider.sites,accrediting_provider",
      course_response
    )
  end

  let(:preview_course_page) { PageObjects::Page::Organisations::CoursePreview.new }

  scenario 'viewing the show courses page' do
    visit preview_provider_course_path('AO', course.course_code)

    expect(preview_course_page.title).to have_content(
      "#{course.name} (#{course.course_code})"
    )

    expect(preview_course_page.sub_title).to have_content(
      provider.provider_name
    )

    expect(preview_course_page.accredited_body).to have_content(
      accrediting_provider.provider_name
    )

    expect(preview_course_page.description).to have_content(
      course.description
    )

    expect(preview_course_page.qualifications).to have_content(
      'PGCE with QTS'
    )

    expect(preview_course_page.funding_option).to have_content(
      decorated_course.funding_option
    )

    expect(preview_course_page.length).to have_content(
      decorated_course.length
    )

    expect(preview_course_page.applications_open_from).to have_content(
      '1 January 2019'
    )

    expect(preview_course_page.start_date).to have_content(
      'September 2019'
    )

    expect(preview_course_page.provider_website).to have_content(
      provider.website
    )

    expect(preview_course_page).to_not have_vacancies

    expect(preview_course_page.about_course).to have_content(
      course.about_course
    )

    expect(preview_course_page.interview_process).to have_content(
      course.interview_process
    )

    expect(preview_course_page.school_placements).to have_content(
      course.how_school_placements_work
    )

    expect(preview_course_page.uk_fees).to have_content(
      '£9,250'
    )

    expect(preview_course_page.eu_fees).to have_content(
      '£9,250'
    )

    expect(preview_course_page.international_fees).to have_content(
      '£9,250'
    )

    expect(preview_course_page.fee_details).to have_content(
      decorated_course.fee_details
    )

    expect(preview_course_page).to_not have_salary_details

    expect(preview_course_page.scholarship_amount).to have_content(
      '£20,000'
    )

    expect(preview_course_page.bursary_amount).to have_content(
      '£22,000'
    )

    expect(preview_course_page.required_qualifications).to have_content(
      course.required_qualifications
    )

    expect(preview_course_page.personal_qualities).to have_content(
      course.personal_qualities
    )

    expect(preview_course_page.other_requirements).to have_content(
      course.other_requirements
    )

    expect(preview_course_page.train_with_us).to have_content(
      provider.train_with_us
    )

    expect(preview_course_page.about_accrediting_body).to have_content(
      course.about_accrediting_body
    )

    expect(preview_course_page.train_with_disability).to have_content(
      provider.train_with_disability
    )

    expect(preview_course_page.contact_email).to have_content(
      provider.email
    )

    expect(preview_course_page.contact_telephone).to have_content(
      provider.telephone
    )

    expect(preview_course_page.contact_website).to have_content(
      provider.website
    )

    expect(preview_course_page.contact_address).to have_content(
      '1 Long Rd E1 ABC'
    )

    expect(preview_course_page).to have_choose_a_training_location_table
    expect(preview_course_page.choose_a_training_location_table).not_to have_content('Suspended site with vacancies')

    [
      ['New site with no vacancies', 'No'],
      ['New site with vacancies', 'Yes'],
      ['Running site with no vacancies', 'No'],
      ['Running site with vacancies', 'Yes']
    ].each_with_index do |site, index|
      name, has_vacancies_string = site

      expect(preview_course_page.choose_a_training_location_table)
        .to have_selector("tbody tr:nth-child(#{index + 1}) strong", text: name)

      expect(preview_course_page.choose_a_training_location_table)
        .to have_selector("tbody tr:nth-child(#{index + 1}) td", text: has_vacancies_string)
    end

    expect(preview_course_page).to have_course_advice
  end

  def jsonapi_site_status(name, study_mode, status)
    jsonapi(:site_status, study_mode, site: jsonapi(:site, location_name: name), status: status)
  end
end
