# coding: utf-8

require 'rails_helper'

feature 'Course show', type: :feature do
  let(:provider) do
    build :provider,
          accredited_body?: false,
          provider_name: "ACME SCITT A0",
          provider_code: 'A0'
  end
  let(:current_recruitment_cycle) { build :recruitment_cycle }
  let(:next_recruitment_cycle) { build :recruitment_cycle, :next_cycle }
  let(:course) do
    build :course,
          has_vacancies?: true,
          course_code: 'C1',
          open_for_applications?: true,
          funding: 'fee',
          fee_uk_eu: 9250,
          last_published_at: '2019-03-05T14:42:34Z',
          provider: provider,
          provider_code: provider.provider_code,
          recruitment_cycle: current_recruitment_cycle,
          site_statuses: [site_status],
          sites: [site]
  end
  let(:site) { build :site, code: 'Z' }
  let(:site_status) do
    build :site_status,
          :full_time_and_part_time,
          site: site
  end

  let(:course_response) do
    course.to_jsonapi(
      include: %i[sites provider accrediting_provider recruitment_cycle]
    )
  end

  before do
    stub_omniauth

    stub_api_v2_request(
      "/recruitment_cycles/#{current_recruitment_cycle.year}",
      data: current_recruitment_cycle.as_json_api
    )

    stub_api_v2_request(
      "/recruitment_cycles/#{current_recruitment_cycle.year}" \
      "/providers/#{provider.provider_code}" \
      "/courses/#{course.course_code}" \
      "?include=sites,provider.sites,accrediting_provider",
      course_response
    )

    visit provider_recruitment_cycle_course_path(provider.provider_code,
                                                 current_recruitment_cycle.year,
                                                 course.course_code)
  end

  let(:course_page) { PageObjects::Page::Organisations::Course.new }
  let(:about_course_page) { PageObjects::Page::Organisations::CourseAbout.new }

  describe 'with a fee paying course' do
    scenario 'it shows the course show page' do
      expect(course_page.caption).to have_content(
        course.description
      )
      expect(course_page.title).to have_content(
        "#{course.name} (#{course.course_code})"
      )
      expect(course_page.about).to have_content(
        course.about_course
      )
      expect(course_page.interview_process).to have_content(
        course.interview_process
      )
      expect(course_page.placements_info).to have_content(
        course.how_school_placements_work
      )
      expect(course_page.length).to have_content(
        course.course_length
      )
      expect(course_page.uk_fees).to have_content(
        '£9,250'
      )
      expect(course_page.international_fees).to have_content(
        course.fee_international
      )
      expect(course_page.fee_details).to have_content(
        course.fee_details
      )
      expect(course_page.required_qualifications).to have_content(
        course.required_qualifications
      )
      expect(course_page.personal_qualities).to have_content(
        course.personal_qualities
      )
      expect(course_page.other_requirements).to have_content(
        course.other_requirements
      )
      expect(course_page.last_published_at).to have_content(
        'Last published: 5 March 2019'
      )
      expect(course_page).to_not have_preview_link

      expect(course_page).to have_link(
        'About this course',
        href: "/organisations/#{provider.provider_code}/#{course.recruitment_cycle_year}/courses/#{course.course_code}/about"
      )
      expect(course_page).to have_link(
        'Course length and fees',
        href: "/organisations/#{provider.provider_code}/#{course.recruitment_cycle_year}/courses/#{course.course_code}/fees"
      )
      expect(course_page).to have_link(
        'Requirements and eligibility',
        href: "/organisations/#{provider.provider_code}/#{course.recruitment_cycle_year}/courses/#{course.course_code}/requirements"
      )
    end
  end

  describe 'with a salaried course' do
    let(:course) {
      build :course,
            funding: 'salary',
            sites: [site],
            provider: provider,
            accrediting_provider: provider
    }

    scenario 'it shows the course show page' do
      expect(course_page.caption).to have_content(
        course.description
      )
      expect(course_page.title).to have_content(
        "#{course.name} (#{course.course_code})"
      )
      expect(course_page.about).to have_content(
        course.about_course
      )
      expect(course_page.interview_process).to have_content(
        course.interview_process
      )
      expect(course_page.placements_info).to have_content(
        course.how_school_placements_work
      )
      expect(course_page.length).to have_content(
        course.course_length
      )
      expect(course_page.salary).to have_content(
        course.salary_details
      )
      expect(course_page.required_qualifications).to have_content(
        course.required_qualifications
      )
      expect(course_page.personal_qualities).to have_content(
        course.personal_qualities
      )
      expect(course_page.other_requirements).to have_content(
        course.other_requirements
      )
      expect(course_page).to_not have_preview_link
    end
  end

  context 'when the course is running' do
    let(:course) {
      build :course,
            findable?: true,
            content_status: 'published',
            ucas_status: 'running',
            has_vacancies?: true,
            open_for_applications?: true,
            provider: provider
    }

    scenario 'it displays a status panel' do
      expect(course_page).to have_status_panel
      expect(course_page.is_findable).to have_content('Yes')
      expect(course_page.has_vacancies).to have_content('Yes')
      expect(course_page.open_for_applications).to have_content('Open')
      expect(course_page.status_tag).to have_content('Published')
    end
  end

  context 'when the course has been rolled over' do
    let(:course) {
      build :course,
            findable?: false,
            content_status: 'rolled_over',
            ucas_status: 'new',
            has_vacancies?: true,
            open_for_applications?: false,
            provider: provider
    }

    scenario 'it displays a status panel' do
      expect(course_page).to have_status_panel
      expect(course_page.is_findable).to have_content('No')
      expect(course_page.status_tag).to have_content('Rolled over')
      expect(course_page.publish).to have_content('Publish in October')
    end
  end

  context 'when the course is not running' do
    let(:course) {
      build :course,
            ucas_status: 'not_running',
            provider: provider
    }

    scenario 'it hides the status panel' do
      expect(course_page).not_to have_status_panel
    end

    scenario 'it shows a warning about the course status' do
      expect(course_page).to have_content('This course is not running.')
    end
  end

  context 'when the course is new' do
    let(:course) {
      build :course,
            findable?: false,
            content_status: 'draft',
            ucas_status: 'new',
            provider: provider
            # recruitment_cycle: current_recruitment_cycle
    }

    scenario 'it displays a status panel' do
      expect(course_page).to have_status_panel
      expect(course_page.is_findable).to have_content('No')
      expect(course_page.status_tag).to have_content('Draft')
      expect(course_page).to have_preview_link
    end

    describe 'publishing' do
      before do
        stub_api_v2_request(
          "/recruitment_cycles/#{current_recruitment_cycle.year}" \
          "/providers/#{provider.provider_code}" \
          "/courses/#{course.course_code}" \
          "?include=sites,provider.sites,accrediting_provider",
          course_response
        )
      end

      context 'without errors' do
        before do
          stub_api_v2_request(
            "/recruitment_cycles/#{current_recruitment_cycle.year}" \
            "/providers/#{provider.provider_code}" \
            "/courses/#{course.course_code}/publish",
            '',
            :post
          )
        end

        scenario 'it shows the show page with success flash' do
          course_page.publish.click

          expect(course_page).to be_displayed
          expect(course_page.success_summary).to have_content("Your course has been published.")
        end
      end

      context 'with errors' do
        before do
          stub_api_v2_request(
            "/recruitment_cycles/#{current_recruitment_cycle.year}" \
            "/providers/#{provider.provider_code}" \
            "/courses/#{course.course_code}" \
            "/publish",
            build(:error, :for_course_publish),
            :post,
            422
          )
          stub_api_v2_request(
            "/recruitment_cycles/#{current_recruitment_cycle.year}" \
            "/providers/#{provider.provider_code}" \
            "?include=courses.accrediting_provider",
            provider.to_jsonapi(include: :courses)
          )
          stub_api_v2_request(
            "/recruitment_cycles/#{current_recruitment_cycle.year}" \
            "/providers/#{provider.provider_code}" \
            "/courses/#{course.course_code}" \
            "/publishable",
            build(:error, :for_course_publish),
            :post,
            422
          )
        end

        scenario 'it shows the show page with validation errors' do
          course_page.publish.click

          expect(page.title).to have_content('Error:')
          expect(course_page).to be_displayed
          expect(course_page.error_summary).to have_content("About course can't be blank")
        end

        scenario 'it deep links and persists errors' do
          course_page.publish.click

          click_link "About course can't be blank", match: :first

          expect(about_course_page.error_flash).to have_content("About course can't be blank")
        end
      end
    end
  end
end
