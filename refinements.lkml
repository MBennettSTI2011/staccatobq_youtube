include: "//youtube/**/*.view.lkml"
include: "//youtube/**/*.explore.lkml"

# #
# Use LookML refinements to refine views and explores defined in the remote project.
# Learn more at: https://cloud.google.com/looker/docs/data-modeling/learning-lookml/refinements
#

explore: channel_end_screens {
  label: "End Screen Performance"
  view_name: channel_end_screens

  join: channel_combined_a2 {
    type: left_outer
    sql_on: ${channel_end_screens.video_id} = ${channel_combined_a2.video_id}
      AND ${channel_end_screens.date_date} = ${channel_combined_a2._data_date} ;;
    relationship: many_to_one
  }
}


# Refine Standard Reports (Point a2 views to a3 tables)

view: +channel_basic_a2 {
  sql_table_name: Staccato2011_Youtube.channel_basic_a3_ytc ;;

  measure: engaged_views {
    type: sum
    sql: ${TABLE}.engaged_views ;;
    description: "The number of times a Short starts to play or replay. (Specific to YouTube Shorts)"
  }

  measure: subscribers_gained {
    type: sum
    sql: ${TABLE}.subscribers_gained ;;
    value_format_name: decimal_0
  }

  measure: subscribers_lost {
    type: sum
    sql: ${TABLE}.subscribers_lost ;;
    value_format_name: decimal_0
  }

  measure: subscriber_churn_rate {
    type: number
    sql: 1.0 * ${subscribers_lost} / NULLIF(${subscribers_gained}, 0) ;;
    value_format_name: percent_2
    description: "Subscribers Lost divided by Subscribers Gained."
  }
}

view: +channel_combined_a2 {
  sql_table_name: Staccato2011_Youtube.channel_combined_a3_ytc ;;
}

view: +channel_device_os_a2 {
  sql_table_name: Staccato2011_Youtube.channel_device_os_a3_ytc ;;
}

view: +channel_playback_location_a2 {
  sql_table_name: Staccato2011_Youtube.channel_playback_location_a3_ytc ;;
}

view: +channel_province_a2 {
  sql_table_name: Staccato2011_Youtube.channel_province_a3_ytc ;;
}

view: +channel_traffic_source_a2 {
  sql_table_name: Staccato2011_Youtube.channel_traffic_source_a3_ytc ;;

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

view: +channel_subtitles_a2 {
  sql_table_name: Staccato2011_Youtube.channel_subtitles_a3_ytc ;;
}

# 2. Refine Derived Tables (Hardcoding the full SQL path)

# Fix video_facts to use the 'a3' combined table
view: +video_facts {
  derived_table: {
    sql: SELECT
          channel_combined_a3.video_id  AS video_id,
          AVG(channel_combined_a3.average_view_duration_seconds ) AS avg_view_duration_s,
          MAX(ROUND((channel_combined_a3.average_view_duration_seconds/(nullif(channel_combined_a3.average_view_duration_percentage/100,0)) ))) AS video_length_seconds
        FROM `staccatodatafactory.Staccato2011_Youtube.channel_combined_a3_ytc` AS channel_combined_a3
        GROUP BY 1
       ;;
  }

  dimension: average_percentage_viewed {
    type: number
    sql: ${TABLE}.avg_view_duration_percentage ;;
    value_format_name: percent_2
  }

  measure: weighted_average_percentage_viewed {
    type: number
    sql: SUM(${TABLE}.average_view_duration_percentage * ${TABLE}.views) / NULLIF(SUM(${TABLE}.views), 0) ;;
    value_format_name: percent_2
    description: "The average percentage of a video your audience watches per view."
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

# New Datatable Reports (Missing from views)

view: channel_end_screens {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.channel_end_screens_a1_ytc ;;

  dimension_group: date {
    type: time
    timeframes: [date, week, month, year]
    sql: ${TABLE}.date ;;
  }

  dimension: video_id {
    type: string
    sql: ${TABLE}.video_id ;;
  }

  dimension: end_screen_element_type {
    type: string
    sql: ${TABLE}.end_screen_element_type ;;
    description: "The type of end screen element (e.g., Subscribe, Best for Viewer)."
  }

  measure: end_screen_element_impressions {
    type: sum
    sql: ${TABLE}.end_screen_element_impressions ;;
    description: "The number of times an end screen element was displayed."
  }

  measure: end_screen_element_clicks {
    type: sum
    sql: ${TABLE}.end_screen_element_clicks ;;
    description: "The number of times an end screen element was clicked."
  }

  measure: end_screen_click_rate {
    type: number
    sql: 1.0 * ${end_screen_element_clicks} / NULLIF(${end_screen_element_impressions}, 0) ;;
    value_format_name: percent_2
    description: "Clicks divided by Impressions."
  }
}

view: playlist_combined {
  sql_table_name: staccatodatafactory.Staccato2011_Youtube.playlist_combined_a2_ytc ;;

  dimension_group: date {
    type: time
    timeframes: [date, week, month, year]
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

  measure: playlist_red_views {
    type: sum
    sql: ${TABLE}.red_views ;;
    label: "YouTube Premium Views"
  }
}
