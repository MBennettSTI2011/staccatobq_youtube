view: period_over_period {
  extension: required

  # 1. User Filters & Parameters
  filter: date_range {
    type: date
    view_label: "Date Comparison"
    label: "1. Date Range"
    description: "Select the date range you want to analyze (e.g., is in the past 30 days, is in year 2024)."
  }

  parameter: comparison_type {
    type: unquoted
    view_label: "Date Comparison"
    label: "2. Compare To"
    allowed_value: { label: "Previous Period (Custom)" value: "period" }
    allowed_value: { label: "Previous Year (Same Days)" value: "year" }
    allowed_value: { label: "Previous Month (Same Days)" value: "month" }
    default_value: "period"
  }

  # 2. Hidden Helper Dimensions for Date Logic
  dimension_group: event {
    # CHANGE THIS to match the date field in your main view (e.g., ${date_date})
    # This is overridden in the refinement, but defined here for validation.
    type: time
    timeframes: [raw, date]
    sql: ${TABLE}.date ;;
    hidden: yes
  }

  dimension: days_in_range {
    type: number
    hidden: yes
    sql: DATE_DIFF({% date_end date_range %}, {% date_start date_range %}, DAY) ;;
  }

  dimension: is_current_period {
    type: yesno
    hidden: yes
    sql: ${event_date} >= {% date_start date_range %}
      AND ${event_date} < {% date_end date_range %} ;;
  }

  dimension: is_previous_period {
    type: yesno
    hidden: yes
    sql:
      {% if comparison_type._parameter_value == 'year' %}
        ${event_date} >= DATE_SUB({% date_start date_range %}, INTERVAL 1 YEAR)
        AND ${event_date} < DATE_SUB({% date_end date_range %}, INTERVAL 1 YEAR)
      {% elsif comparison_type._parameter_value == 'month' %}
        ${event_date} >= DATE_SUB({% date_start date_range %}, INTERVAL 1 MONTH)
        AND ${event_date} < DATE_SUB({% date_end date_range %}, INTERVAL 1 MONTH)
      {% else %}
        ${event_date} >= DATE_SUB({% date_start date_range %}, INTERVAL ${days_in_range} DAY)
        AND ${event_date} < {% date_start date_range %}
      {% endif %} ;;
  }

  dimension: period {
    view_label: "Date Comparison"
    label: "Period"
    description: "Pivot on this field to compare Current vs Previous"
    type: string
    case: {
      when: {
        sql: ${is_current_period} ;;
        label: "Current Period"
      }
      when: {
        sql: ${is_previous_period} ;;
        label: "Previous Period"
      }
    }
  }

  dimension: day_in_period {
    type: number
    label: "Day of Period"
    group_label: "Date Comparison"
    description: "Use this dimension on the X-Axis to overlay Current vs Previous periods."
    sql: DATE_DIFF(${event_date}, {% date_start date_range %}, DAY) + 1 ;;
  }

}
