require 'rails_helper'

feature 'Edit course start date', type: :feature do
  let(:current_recruitment_cycle) { build(:recruitment_cycle) }
  let(:start_date_page) { PageObjects::Page::Organisations::CourseStartDate.new }
  let(:course_details_page) { PageObjects::Page::Organisations::CourseDetails.new }
  let(:provider) { build(:provider) }

  before do
    stub_omniauth
    stub_api_v2_request(
      "/recruitment_cycles/#{current_recruitment_cycle.year}",
      current_recruitment_cycle.to_jsonapi
    )
    stub_api_v2_request(
      "/recruitment_cycles/#{current_recruitment_cycle.year}" \
      "/providers/#{provider.provider_code}?include=courses.accrediting_provider",
      build(:provider).to_jsonapi(include: %i[courses accrediting_provider])
    )

    stub_course_request
    stub_course_details_tab
    start_date_page.load_with_course(course)
  end

  context 'a course with a start date of october 2019' do
    let(:course) do
      build(
        :course,
        start_date: 'October 2019',
        edit_options: {
          start_dates: ['October 2019', 'November 2019']
        },
        provider: provider
      )
    end

    scenario 'can cancel changes' do
      click_on 'Cancel changes'
      expect(course_details_page).to be_displayed
    end

    scenario 'can navigate to the edit screen and back again' do
      course_details_page.load_with_course(course)
      click_on 'Change start date'
      expect(start_date_page).to be_displayed
      click_on 'Back'
      expect(course_details_page).to be_displayed
    end

    scenario 'presents a choice for each start date' do
      expect(start_date_page).to have_start_date_field
      expect(start_date_page.start_date_field)
        .to have_selector('[value="October 2019"]')
      expect(start_date_page.start_date_field)
        .to have_selector('[value="November 2019"]')
    end

    scenario 'has the correct value selected' do
      expect(start_date_page.start_date_field.value).to eq('October 2019')
    end

    scenario 'can be updated' do
      update_course_stub = stub_api_v2_request(
        "/recruitment_cycles/#{course.recruitment_cycle.year}" \
        "/providers/#{provider.provider_code}" \
        "/courses/#{course.course_code}",
        course.to_jsonapi,
        :patch, 200
      )

      select('November 2019')
      click_on 'Save'

      expect(course_details_page).to be_displayed
      expect(course_details_page.flash).to have_content('Your changes have been saved')
      expect(update_course_stub).to have_been_requested
    end
  end

  def stub_course_request
    stub_api_v2_request(
      "/recruitment_cycles/#{current_recruitment_cycle.year}" \
      "/providers/#{provider.provider_code}/courses" \
      "/#{course.course_code}",
      course.to_jsonapi
    )
  end

  def stub_course_details_tab
    stub_api_v2_request(
      "/recruitment_cycles/#{course.recruitment_cycle.year}" \
      "/providers/#{provider.provider_code}" \
      "/courses/#{course.course_code}" \
      "?include=sites,provider.sites,accrediting_provider",
      course.to_jsonapi(include: [:sites, :accrediting_provider, :recruitment_cycle, provider: :sites])
    )
  end
end