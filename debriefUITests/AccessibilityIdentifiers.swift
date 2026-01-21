//
//  AccessibilityIdentifiers.swift
//  debriefUITests
//
//  Created by Mustafa Yildirim on 21/01/2026.
//

import Foundation

/// Centralized accessibility identifiers for UI testing
/// These must match identifiers set in the main app via .accessibilityIdentifier()
enum AccessibilityIdentifiers {

    // MARK: - Login Screen

    enum Login {
        static let googleSignInButton = "login_google_sign_in_button"
        static let privacyPolicyLink = "login_privacy_policy_link"
        static let termsOfServiceLink = "login_terms_of_service_link"
        static let loadingIndicator = "login_loading_indicator"
        static let errorMessage = "login_error_message"
        static let logoImage = "login_logo_image"
        static let appVersionLabel = "login_app_version"
    }

    // MARK: - Tab Bar

    enum TabBar {
        static let debriefsTab = "tab_debriefs"
        static let statsTab = "tab_stats"
        static let recordButton = "tab_record"
        static let contactsTab = "tab_contacts"
        static let settingsTab = "tab_settings"
    }

    // MARK: - Record Screen

    enum Record {
        static let recordingTimer = "record_timer"
        static let stopButton = "record_stop_button"
        static let cancelButton = "record_cancel_button"
        static let pulseAnimation = "record_pulse_animation"

        // Contact Selection
        static let contactSearchField = "record_contact_search"
        static let contactList = "record_contact_list"
        static let saveDebriefButton = "record_save_debrief_button"
        static let selectedContactCheckmark = "record_contact_selected"

        // Quota Exceeded
        static let quotaExceededIcon = "record_quota_exceeded_icon"
        static let quotaExceededTitle = "record_quota_exceeded_title"
        static let upgradeButton = "record_upgrade_button"
        static let closeButton = "record_close_button"
    }

    // MARK: - Debriefs Feed

    enum DebriefsFeed {
        static let searchButton = "feed_search_button"
        static let filterButton = "feed_filter_button"
        static let filterActiveIndicator = "feed_filter_active"
        static let dailyStatsCard = "feed_daily_stats"
        static let debriefList = "feed_debrief_list"
        static let recentPeopleStrip = "feed_recent_people"
        static let pullToRefresh = "feed_refresh"
        static let loadMoreIndicator = "feed_load_more"

        // Filter Chips
        static let filterChip = "feed_filter_chip_"
        static let removeFilterButton = "feed_remove_filter_"
    }

    // MARK: - Debrief Detail

    enum DebriefDetail {
        static let contactName = "detail_contact_name"
        static let statusBadge = "detail_status_badge"
        static let dateLabel = "detail_date"
        static let durationLabel = "detail_duration"

        // Action Items
        static let actionItemsSection = "detail_action_items"
        static let actionItemRow = "detail_action_item_"
        static let actionItemCheckbox = "detail_action_item_checkbox_"
        static let actionItemText = "detail_action_item_text_"
        static let addActionItemButton = "detail_add_action_item"
        static let setReminderButton = "detail_set_reminder"
        static let clearSelectionsButton = "detail_clear_selections"

        // Audio Player
        static let playPauseButton = "detail_play_pause"
        static let seekSlider = "detail_seek_slider"
        static let currentTimeLabel = "detail_current_time"
        static let durationTimeLabel = "detail_duration_time"
        static let speedButton1x = "detail_speed_1x"
        static let speedButton15x = "detail_speed_1_5x"
        static let speedButton2x = "detail_speed_2x"

        // Transcript
        static let summarySection = "detail_summary"
        static let summaryExpandButton = "detail_summary_expand"
        static let transcriptPreview = "detail_transcript_preview"
        static let fullTranscriptButton = "detail_full_transcript"

        // Actions
        static let exportButton = "detail_export"
        static let deleteButton = "detail_delete"
        static let deleteConfirmButton = "detail_delete_confirm"
    }

    // MARK: - Contacts

    enum Contacts {
        static let searchField = "contacts_search"
        static let contactList = "contacts_list"
        static let contactRow = "contacts_row_"
        static let contactAvatar = "contacts_avatar_"
        static let emptyStateView = "contacts_empty"
        static let permissionDeniedView = "contacts_permission_denied"
        static let loadingIndicator = "contacts_loading"
    }

    // MARK: - Contact Detail

    enum ContactDetail {
        static let profileHeader = "contact_profile_header"
        static let avatarImage = "contact_avatar"
        static let nameLabel = "contact_name"
        static let handleLabel = "contact_handle"

        // Stats Cards
        static let debriefsStatCard = "contact_stat_debriefs"
        static let lastMetStatCard = "contact_stat_last_met"
        static let durationStatCard = "contact_stat_duration"
        static let statInfoButton = "contact_stat_info_"

        // History
        static let searchField = "contact_search"
        static let filterButton = "contact_filter"
        static let interactionHistory = "contact_history"
        static let scrollToTopButton = "contact_scroll_top"
    }

    // MARK: - Stats

    enum Stats {
        static let segmentedControl = "stats_segment_control"
        static let overviewTab = "stats_tab_overview"
        static let chartsTab = "stats_tab_charts"
        static let insightsTab = "stats_tab_insights"

        // Current Plan
        static let planCard = "stats_plan_card"
        static let planName = "stats_plan_name"

        // Weekly Stats Grid
        static let weeklyStatsGrid = "stats_weekly_grid"
        static let totalDebriefsCard = "stats_total_debriefs"
        static let durationCard = "stats_duration"
        static let actionItemsCard = "stats_action_items"
        static let activeContactsCard = "stats_active_contacts"

        // Quick Stats
        static let avgDurationRow = "stats_avg_duration"
        static let tasksCreatedRow = "stats_tasks_created"
        static let mostActiveDayRow = "stats_most_active_day"
        static let longestStreakRow = "stats_longest_streak"
        static let quickStatLoading = "stats_quick_loading"

        // Quota
        static let quotaSection = "stats_quota_section"
        static let quotaInfoButton = "stats_quota_info"
        static let recordingsBar = "stats_quota_recordings"
        static let minutesBar = "stats_quota_minutes"
        static let storageBar = "stats_quota_storage"
        static let billingCountdown = "stats_billing_countdown"

        // Top Contacts
        static let topContactsSection = "stats_top_contacts"
        static let topContactRow = "stats_top_contact_"
    }

    // MARK: - Search

    enum Search {
        static let searchField = "search_field"
        static let clearButton = "search_clear"
        static let doneButton = "search_done"
        static let infoButton = "search_info"
        static let loadingAnimation = "search_loading"
        static let emptyState = "search_empty"
        static let noResultsState = "search_no_results"
        static let resultsList = "search_results"
        static let resultItem = "search_result_"
    }

    // MARK: - Settings

    enum Settings {
        static let privacyBanner = "settings_privacy_banner"
        static let profileRow = "settings_profile"
        static let signOutButton = "settings_sign_out"

        // Plan
        static let currentPlanRow = "settings_current_plan"

        // Preferences
        static let notificationsToggle = "settings_notifications_toggle"

        // Privacy & Support
        static let privacyPolicyButton = "settings_privacy_policy"
        static let dataHandlingButton = "settings_data_handling"
        static let helpCenterButton = "settings_help_center"

        // Storage
        static let storageUsedLabel = "settings_storage_used"
        static let freeSpaceButton = "settings_free_space"
        static let freeSpaceConfirmAlert = "settings_free_space_confirm"

        // App Info
        static let appVersionLabel = "settings_app_version"

        // Danger Zone
        static let deleteAccountButton = "settings_delete_account"
        static let deleteWarningSheet = "settings_delete_warning"
        static let deleteConfirmInput = "settings_delete_confirm_input"
        static let deleteConfirmButton = "settings_delete_confirm_button"
    }

    // MARK: - Filter Sheet

    enum Filter {
        static let dateRangeSection = "filter_date_range"
        static let dateOptionAll = "filter_date_all"
        static let dateOptionToday = "filter_date_today"
        static let dateOptionThisWeek = "filter_date_this_week"
        static let dateOptionThisMonth = "filter_date_this_month"
        static let dateOptionCustom = "filter_date_custom"
        static let customStartDate = "filter_custom_start"
        static let customEndDate = "filter_custom_end"
        static let contactSection = "filter_contact"
        static let applyButton = "filter_apply"
        static let resetButton = "filter_reset"
    }

    // MARK: - Common

    enum Common {
        static let loadingOverlay = "common_loading_overlay"
        static let errorAlert = "common_error_alert"
        static let successToast = "common_success_toast"
        static let confirmationAlert = "common_confirmation_alert"
        static let alertOKButton = "common_alert_ok"
        static let alertCancelButton = "common_alert_cancel"
    }
}
