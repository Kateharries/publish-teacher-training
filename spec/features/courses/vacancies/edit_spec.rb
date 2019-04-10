require 'rails_helper'

feature 'Edit course vacancies', type: :feature do
  let(:course) do
    jsonapi(
      :course,
      :with_full_time_or_part_time_vacancy,
      site_statuses: [site_status],
      provider: jsonapi(:provider)
    ).render
  end
  let(:course_without_full_time_vacancy) do
    jsonapi(
      :course,
      :with_full_time_or_part_time_vacancy,
      course_code:   course_attributes[:course_code],
      site_statuses: [
        jsonapi(:site_status, :part_time, id: site_status.id, site: site)
      ]
    ).render
  end
  let(:course_attributes) { course[:data][:attributes] }
  let(:site) { jsonapi(:site) }
  let(:site_status) do
    jsonapi(:site_status, :full_time_and_part_time, site: site)
  end
  let(:edit_vacancies_path) do
    "/organisations/AO/courses/#{course_attributes[:course_code]}/vacancies"
  end
  let!(:sync_courses_request_stub) do
    stub_request(
      :post,
      "http://localhost:3001/api/v2/providers/AO/courses/" \
        "#{course_attributes[:course_code]}/sync_with_search_and_compare"
    ).to_return(status: 201, body: "")
  end

  before do
    stub_omniauth
    stub_session_create
    stub_api_v2_request(
      "/providers/AO?include=courses.accrediting_provider",
      jsonapi(:provider).render
    )
    stub_api_v2_request(
      "/providers/AO/courses/#{course_attributes[:course_code]}?include=site_statuses.site",
      course
    )

    visit edit_vacancies_path
  end

  scenario 'viewing the edit vacancies page' do
    expect(page).to have_link('Back', href: provider_courses_path('AO'))
    expect(page).to have_link('Cancel changes', href: provider_courses_path('AO'))
    expect(find('h1')).to have_content('Edit vacancies')
    expect(find('.govuk-caption-xl')).to have_content(
      "#{course_attributes[:name]} (#{course_attributes[:course_code]})"
    )
  end

  context 'site_statuses#running' do
    let(:course) do
      jsonapi(
        :course,
        :with_full_time_or_part_time_vacancy,
        site_statuses: [running_site_status, non_running_site_status]
      ).render
    end

    let(:site_running) { jsonapi(:site, location_name: 'Big Uni') }
    let(:site_not_running) { jsonapi(:site, location_name: 'Small Uni') }

    let(:running_site_status) do
      jsonapi(:site_status, :full_time_and_part_time, site: site_running, status: 'running')
    end
    let(:non_running_site_status) do
      jsonapi(:site_status, :full_time_and_part_time, site: site_not_running, status: 'suspended')
    end

    scenario 'only render site_statuses that are running' do
      expect(page).to have_field("Big Uni (Full time)")
      expect(page).to_not have_field("Small Uni (Full time)")
    end
  end

  context 'removing vacancies' do
    let(:course_without_vacancies) do
      jsonapi(
        :course,
        :full_time_or_part_time,
        course_code:   course_attributes[:course_code],
        site_statuses: [
          jsonapi(:site_status, :no_vacancies, id: site_status.id, site: site)
        ]
      ).render
    end

    before do
      stub_request(
        :patch,
        "http://localhost:3001/api/v2/site_statuses/#{site_status.id}"
      )
    end

    scenario 'removing a full time vacancy' do
      uncheck(
        "#{site.attributes[:location_name]} (Full time)",
        allow_label_click: true
      )

      stub_api_v2_request(
        "/providers/AO/courses/#{course_attributes[:course_code]}?include=site_statuses.site",
        course_without_full_time_vacancy
      )

      click_on 'Publish changes'

      expect(page.find('.govuk-success-summary')).to have_content(
        'Course vacancies published'
      )
      expect(find('h1')).to have_content('Courses')
      expect(sync_courses_request_stub).to have_been_requested
    end

    scenario 'removing all vacancies' do
      choose 'There are no vacancies'

      stub_api_v2_request(
        "/providers/AO/courses/#{course_attributes[:course_code]}?include=site_statuses.site",
        course_without_vacancies
      )

      click_on 'Publish changes'

      expect(page.find('.govuk-success-summary')).to have_content(
        'Course vacancies published'
      )
      expect(find('h1')).to have_content('Courses')
      expect(sync_courses_request_stub).to have_been_requested
    end
  end

  context 'adding vacancies' do
    before do
      stub_api_v2_request(
        "/providers/AO/courses/#{course_attributes[:course_code]}?include=site_statuses.site",
        course_without_full_time_vacancy
      )
      stub_request(
        :patch,
        "http://localhost:3001/api/v2/site_statuses/#{site_status.id}"
      )
    end

    scenario 'adding a part time vacancy' do
      check(
        "#{site.attributes[:location_name]} (Full time)",
        allow_label_click: true
      )

      stub_api_v2_request(
        "/providers/AO/courses/#{course_attributes[:course_code]}?include=site_statuses.site",
        course
      )

      click_on 'Publish changes'

      expect(page.find('.govuk-success-summary')).to have_content(
        'Course vacancies published'
      )
      expect(find('h1')).to have_content('Courses')
      expect(sync_courses_request_stub).to have_been_requested
    end
  end
end
