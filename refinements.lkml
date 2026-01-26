include: "//youtube/**/*.view.lkml"
include: "//youtube/**/*.explore.lkml"
include: "period_over_period.view.lkml"

# #
# Use LookML refinements to refine views and explores defined in the remote project.
# Learn more at: https://cloud.google.com/looker/docs/data-modeling/learning-lookml/refinements
#

explore: +channel_combined_a2 {
  join: channel_end_screens {
    view_label: "End Screens"
    type: left_outer
    relationship: one_to_many
    sql_on: ${channel_combined_a2.video_id} = ${channel_end_screens.video_id}
      AND ${channel_combined_a2.date} = ${channel_end_screens.date_date} ;;
  }
}

explore: playlist_combined_report {
  label: "Playlist Performance"
  view_label: "Playlist Metrics"
}

#########################################################
# 1. CORE REPORT REFINEMENTS (Points to 'a3' tables)
#########################################################

view: +channel_basic_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_basic_a3_ytc ;;

  # Added 'month_name' to the timeframe list
  dimension_group: _data {
    timeframes: [raw, date, week, month, month_name, quarter, year]
  }

  # --- New Power Metrics ---
  measure: engaged_views {
    type: sum
    sql: ${TABLE}.engaged_views ;;
    description: "The number of times a Short starts to play or replay. (Specific to YouTube Shorts)"
  }

  measure: subscribers_gained {
    type: sum
    sql: ${TABLE}.subscribers_gained ;;
  }

  measure: subscribers_lost {
    type: sum
    sql: ${TABLE}.subscribers_lost ;;
  }

  measure: subscriber_churn_rate {
    type: number
    sql: 1.0 * ${subscribers_lost} / NULLIF(${subscribers_gained}, 0) ;;
    value_format_name: percent_2
    description: "Subscribers Lost divided by Subscribers Gained"
  }
}

view: +channel_combined_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_combined_a3_ytc ;;
  dimension_group: _data {
    timeframes: [time, date, week, month, month_name, quarter, year]
  }
}

view: +channel_traffic_source_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_traffic_source_a3_ytc ;;
  dimension_group: _data {
    timeframes: [raw, date, week, month, month_name, quarter, year]
  }

  measure: impressions {
    type: sum
    sql: ${TABLE}.impressions ;;
    description: "How many times your video thumbnails were shown to viewers."
  }

  measure: source_click_through_rate {
    type: number
    sql: 1.0 * ${views} / NULLIF(${impressions}, 0) ;;
    value_format_name: percent_2
    description: "Clicks (Views) divided by Impressions for this specific traffic source."
  }
}

#########################################################
# 2. STANDARD VIEW REFINEMENTS (Points a2 -> a3)
#########################################################

view: +channel_device_os_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_device_os_a3_ytc ;;
}

view: +channel_playback_location_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_playback_location_a3_ytc ;;
}

view: +channel_province_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_province_a3_ytc ;;
}

view: +channel_subtitles_a2 {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_subtitles_a3_ytc ;;
}

#########################################################
# 3. DERIVED TABLE FIXES (Hardcoding SQL paths)
#########################################################

view: +video_facts {
  derived_table: {
    sql: SELECT
          channel_combined_a3.video_id  AS video_id,
          AVG(channel_combined_a3.average_view_duration_seconds ) AS avg_view_duration_s,
          MAX(ROUND((channel_combined_a3.average_view_duration_seconds/(nullif(channel_combined_a3.average_view_duration_percentage/100,0)) ))) AS video_length_seconds,
          -- Added Weighted Average Percentage Viewed
          SUM(channel_combined_a3.average_view_duration_percentage * channel_combined_a3.views) / NULLIF(SUM(channel_combined_a3.views), 0) as weighted_avg_percentage
        FROM `staccatodatafactory.Staccato2011_Youtube.channel_combined_a3_ytc` AS channel_combined_a3
        GROUP BY 1
       ;;
  }

  measure: weighted_average_percentage_viewed {
    type: number
    sql: ${TABLE}.weighted_avg_percentage ;;
    value_format_name: percent_2
    description: "Average percentage of video watched, weighted by views."
  }
}

view: +video_playlist_facts {
  derived_table: {
    sql: SELECT date, video_id, playlist_id
      , sum(playlist_starts) as starts
      , sum(playlist_saves_added) as saves_added
      , sum(playlist_saves_removed) as saves_removed
      , sum(views) as views
      FROM `staccatodatafactory.Staccato2011_Youtube.p_playlist_basic_a2_ytc`
      group by 1, 2, 3
       ;;
  }
}

#########################################################
# 4. NEW VIEWS (Unlocking End Screens & Playlist Reports)
#########################################################

view: channel_end_screens {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_end_screens_a1_ytc ;;

  dimension_group: date {
    type: time
    timeframes: [date, week, month, month_name, year]
    sql: ${TABLE}.date ;;
  }

  dimension: video_id {
    type: string
    sql: ${TABLE}.video_id ;;
  }

  dimension: end_screen_element_type {
    type: string
    sql: ${TABLE}.end_screen_element_type ;;
  }

  measure: end_screen_element_clicks {
    type: sum
    sql: ${TABLE}.end_screen_element_clicks ;;
  }

  measure: end_screen_element_impressions {
    type: sum
    sql: ${TABLE}.end_screen_element_impressions ;;
  }

  measure: end_screen_ctr {
    type: number
    sql: 1.0 * ${end_screen_element_clicks} / NULLIF(${end_screen_element_impressions}, 0) ;;
    value_format_name: percent_2
  }
}

view: playlist_combined_report {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.playlist_combined_a2_ytc ;;

  dimension_group: date {
    type: time
    timeframes: [date, week, month, month_name, year]
    sql: ${TABLE}.date ;;
  }

  dimension: playlist_id {
    type: string
    sql: ${TABLE}.playlist_id ;;
  }

  measure: playlist_views {
    type: sum
    sql: ${TABLE}.views ;;
  }

  measure: playlist_average_view_duration {
    type: average
    sql: ${TABLE}.average_view_duration_seconds ;;
    value_format: "h:mm:ss"
  }
}

#########################################################
# 5. Date Comparison
#########################################################

view: +channel_combined_a2 {
  extends: [period_over_period]

  # Map the 'event' dimension to your actual date field
  dimension_group: event {
    sql: ${TABLE}.date ;;
  }

  # --- Comparison Measures (Views) ---

  measure: views_current {
    view_label: "Date Comparison"
    type: sum
    sql: ${TABLE}.views ;;
    filters: [is_current_period: "yes"]
  }

  measure: views_previous {
    view_label: "Date Comparison"
    type: sum
    sql: ${TABLE}.views ;;
    filters: [is_previous_period: "yes"]
  }

  measure: views_change_pct {
    view_label: "Date Comparison"
    label: "Views % Change"
    type: number
    sql: 1.0 * (${views_current} - ${views_previous}) / NULLIF(${views_previous}, 0) ;;
    value_format_name: percent_2
  }

  # --- Comparison Measures (Watch Time) ---

  measure: watch_time_current {
    view_label: "Date Comparison"
    label: "Watch Time (Current)"
    type: sum
    sql: ${TABLE}.average_view_duration_seconds * ${TABLE}.views ;; # Approximate calculation if total not available
    filters: [is_current_period: "yes"]
  }

  measure: watch_time_previous {
    view_label: "Date Comparison"
    label: "Watch Time (Previous)"
    type: sum
    sql: ${TABLE}.average_view_duration_seconds * ${TABLE}.views ;;
    filters: [is_previous_period: "yes"]
  }

  measure: watch_time_change_pct {
    view_label: "Date Comparison"
    label: "Watch Time % Change"
    type: number
    sql: 1.0 * (${watch_time_current} - ${watch_time_previous}) / NULLIF(${watch_time_previous}, 0) ;;
    value_format_name: percent_2
  }
}
