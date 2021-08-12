class GcseRequirementsComponent < ViewComponent::Base
  attr_reader :course, :errors

  def initialize(course:, errors: nil)
    @course = course
    @errors = errors
  end

  def inset_text_css_classes
    messages = if errors
                 errors.values.flatten
               end

    if messages&.include?("Enter GCSE requirements")
      "app-inset-text--narrow-border app-inset-text--error"
    else
      "app-inset-text--narrow-border app-inset-text--important"
    end
  end

private

  def required_gcse_content(course)
    case course.level
    when "primary"
      "GCSE grade  #{course.gcse_grade_required} (C) or above in English, maths and science, or equivalent qualification"
    when "secondary"
      "GCSE grade #{course.gcse_grade_required} (C) or above in English and maths, or equivalent qualification"
    end
  end

  def pending_gcse_content(course)
    if course.accept_pending_gcse
      "We’ll consider candidates who are currently taking GCSEs."
    else
      "We will not consider candidates with pending GCSEs."
    end
  end

  def gcse_equivalency_content(course)
    if course.accept_gcse_equivalency?
      "We’ll consider candidates who need to take a GCSE equivalency test in #{equivalencies}."
    else
      'We will not consider candidates who need to take GCSE equivalency tests.'
    end
  end

  def equivalencies
    subjects = []
    subjects << 'English' if course.accept_english_gcse_equivalency.present?
    subjects << 'maths' if course.accept_maths_gcse_equivalency.present?
    subjects << 'science' if course.accept_science_gcse_equivalency.present?

    subjects.to_sentence(last_word_connector: ' and ')
  end
end
