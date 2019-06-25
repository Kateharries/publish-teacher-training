class Course < Base
  belongs_to :provider, param: :provider_code
  has_many :site_statuses
  has_many :sites, through: :site_statuses, source: :site

  custom_endpoint :sync_with_search_and_compare, on: :member, request_method: :post
  custom_endpoint :publish, on: :member, request_method: :post

  property :fee_international, type: :integer
  property :fee_uk_eu, type: :integer

  self.primary_key = :course_code

  def full_time?
    study_mode == 'full_time'
  end

  def part_time?
    study_mode == 'part_time'
  end

  def full_time_or_part_time?
    study_mode == 'full_time_or_part_time'
  end

  def is_running?
    ucas_status == 'running'
  end

  def not_running?
    ucas_status == 'not_running'
  end

  def new_and_not_running?
    ucas_status == 'new'
  end

  def has_fees?
    funding == 'fee'
  end

  def has_unpublished_changes?
    content_status == "published_with_unpublished_changes"
  end

  def is_published?
    content_status == 'published'
  end

  def running_site_statuses
    site_statuses.select(&:running?)
  end

  def has_multiple_running_sites_or_study_modes?
    running_site_statuses.length > 1 || full_time_or_part_time?
  end
end
