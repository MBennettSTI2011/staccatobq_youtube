###################################################################################
# This is a read-only file! Its contents can be edited through the Marketplace UI #
# See the docs at: https://cloud.google.com/looker/docs/data-modeling/marketplace              #
###################################################################################

marketplace_ref: {
  listing: "youtube"
  version: "1.0.2"
  models: ["youtube_channel_owner"]
  override_constant: CONNECTION_NAME { value:"connection_name" }
  override_constant: schema { value:"youtube_ads_export" }
  override_constant: table_suffix { value:"yrc" }
}
