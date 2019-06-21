module Courses
  class VacanciesController < ApplicationController
    before_action(
      :build_course,
      :build_site_statuses
    )

    def edit; end

    def update
      unless params[:change_vacancies_confirmation]
        error_message = if @course.has_vacancies?
                          "Please confirm there are no vacancies to close applications"
                        else
                          "Please confirm there are vacancies to reopen applications"
                        end
        @errors = { change_vacancies_confirmation: [error_message] }
        return render(:edit)
      end

      @course.has_multiple_running_sites_or_study_modes? ? update_vacancies_for_multiple_sites : update_vacancies_for_a_single_site
      @course.sync_with_search_and_compare(provider_code: params[:provider_code])
      flash[:success] = 'Course vacancies published'
      redirect_to provider_courses_path(params[:provider_code])
    end

  private

    def update_vacancies_for_a_single_site
      case params[:change_vacancies_confirmation]
      when 'no_vacancies_confirmation'
        vac_status = 'no_vacancies'
      when 'has_vacancies_confirmation'
        vac_status = @course.full_time? ? "full_time_vacancies" : "part_time_vacancies"
      end

      @site_statuses.each do |site_status|
        site_status.vac_status = vac_status
        site_status.save
      end
    end

    def update_vacancies_for_multiple_sites
      params.dig(:course, :site_status_attributes)
        &.values&.each do |vacancy_status|
          site_status = find_site_status vacancy_status[:id]
          # Set all site_status.vac_status to 'no_vacancies' if radio button is checked
          site_status.vac_status = if params[:course][:has_vacancies] == 'false'
                                     'no_vacancies'
                                   else
                                     VacancyStatusDeterminationService.call(
                                       vacancy_status_full_time: vacancy_status[:full_time],
                                       vacancy_status_part_time: vacancy_status[:part_time],
                                       course:                   @course
                                     )
                                   end
          site_status.save
        end
    end

    def build_course
      @course = Course.includes(site_statuses: [:site]).where(provider_code: params[:provider_code]).find(params[:code]).first
    end

    def build_site_statuses
      @site_statuses = @course.running_site_statuses
    end

    def find_site_status(id)
      @site_statuses.find { |site_status_by_id| site_status_by_id.id == id }
    end
  end
end
