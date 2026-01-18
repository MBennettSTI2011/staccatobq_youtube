include: "//youtube/**/*.view.lkml"
include: "//youtube/**/*.explore.lkml"

# #
# Use LookML refinements to refine views and explores defined in the remote project.
# Learn more at: https://cloud.google.com/looker/docs/data-modeling/learning-lookml/refinements
#
# 1. Refine Standard Reports (Point a2 views to a3 tables)

view: +channel_basic_a2 {
  sql_table_name: Staccato2011_Youtube.channel_basic_a3_ytc ;;
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
}

# Fix video_playlist_facts to use the 'a2' playlist table
# (Note: I used your project name 'staccatodatafactory' here directly)
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
