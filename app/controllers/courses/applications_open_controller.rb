module Courses
  class ApplicationsOpenController < ApplicationController
    before_action :build_recruitment_cycle
    before_action :build_course_params, only: :update
    include CourseBasicDetailConcern

    def continue
      build_course_params
      super
    end

  private

    def errors; end

    def actual_params
      params.require(:course)
        .except(
          :qualification,
          :maths,
          :english,
          :science,
          :funding_type,
          :level,
          :is_send,
          :study_mode,
          :age_range_in_years,
          :sites_ids,
          :subjects_ids,
          :goto_confirmation,
        )
        .permit(
          :applications_open_from,
          :day,
          :month,
          :year,
        )
    end

    # This is needed to handle the fact that dates are optionally specified as year/month/day in the UI
    # This method assigns the params to the correct YYYY-MM-DD value given what is selected
    def build_course_params
      if params.key?(:course)
        applications_open_from =
          if actual_params["applications_open_from"] == "other"
            "#{actual_params['year']}-#{actual_params['month']}-#{actual_params['day']}"
          else
            actual_params["applications_open_from"]
          end
        params["course"]["applications_open_from"] = applications_open_from
      else
        ActionController::Parameters.new({}).permit
      end
    end

    def build_recruitment_cycle
      cycle_year = params.fetch(
        :recruitment_cycle_year,
        Settings.current_cycle,
      )

      @recruitment_cycle = RecruitmentCycle.find(cycle_year).first
    end

    def current_step
      :applications_open
    end
  end
end
