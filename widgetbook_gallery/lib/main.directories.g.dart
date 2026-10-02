// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_gallery/usecases/design_system.dart'
    as _widgetbook_gallery_usecases_design_system;
import 'package:widgetbook_gallery/usecases/roster_components.dart'
    as _widgetbook_gallery_usecases_roster_components;
import 'package:widgetbook_gallery/usecases/roster_live_preview.dart'
    as _widgetbook_gallery_usecases_roster_live_preview;
import 'package:widgetbook_gallery/usecases/student_components.dart'
    as _widgetbook_gallery_usecases_student_components;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'design_system',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'presentation',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'DesignSystemDashboard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Theme Settings',
                builder:
                    _widgetbook_gallery_usecases_design_system.themeSettings,
              )
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'DesignSystemPreview',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Four palettes · Light & Dark',
                builder: _widgetbook_gallery_usecases_design_system.palettes,
              )
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'components',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'SystemPage',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Directory to profile journey',
                    builder: _widgetbook_gallery_usecases_student_components
                        .studentJourney,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'SystemPageHeader',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Header with action and filters',
                    builder: _widgetbook_gallery_usecases_student_components
                        .pageHeaderFull,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Header without filters',
                    builder: _widgetbook_gallery_usecases_student_components
                        .pageHeaderPlain,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'SystemPageInfoBar',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Scope and trailing control',
                    builder: _widgetbook_gallery_usecases_student_components
                        .pageInfoBar,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'SystemPillSegment',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Disabled pills',
                    builder: _widgetbook_gallery_usecases_student_components
                        .pillDisabled,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Status tones',
                    builder: _widgetbook_gallery_usecases_student_components
                        .pillStatusTones,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'View switch',
                    builder: _widgetbook_gallery_usecases_student_components
                        .pillViewSwitch,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'SystemSectionCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Section and actions',
                    builder: _widgetbook_gallery_usecases_student_components
                        .sectionCard,
                  )
                ],
              ),
            ],
          ),
        ],
      )
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'main',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'components',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'attendance',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'AttendanceRecordCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Leave with reason',
                    builder: _widgetbook_gallery_usecases_student_components
                        .attendanceLeave,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Long name in split view',
                    builder: _widgetbook_gallery_usecases_student_components
                        .attendanceNarrow,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Present',
                    builder: _widgetbook_gallery_usecases_student_components
                        .attendancePresent,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Readonly attendance',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .attendanceReadonly,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Unmarked attendance',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .attendanceUnmarked,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'AttendanceStatusChip',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Attendance status chips',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .attendanceChips,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'AttendanceSummaryBar',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Mixed statuses',
                    builder: _widgetbook_gallery_usecases_student_components
                        .attendanceSummary,
                  )
                ],
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'avatar',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'StudentAvatar',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default boy and girl',
                    builder: _widgetbook_gallery_usecases_student_components
                        .avatarDefaults,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Loading photo',
                    builder: _widgetbook_gallery_usecases_student_components
                        .avatarLoading,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Missing photo and retry',
                    builder: _widgetbook_gallery_usecases_student_components
                        .avatarError,
                  ),
                ],
              )
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'login',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'LoginSubmitButton',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Disabled login',
                    builder: _widgetbook_gallery_usecases_student_components
                        .disabledLogin,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Login action',
                    builder: _widgetbook_gallery_usecases_student_components
                        .loginAction,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Submitting login',
                    builder: _widgetbook_gallery_usecases_student_components
                        .submittingLogin,
                  ),
                ],
              )
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'privacy',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'PrivacyPolicyButton',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Disabled policy action',
                    builder: _widgetbook_gallery_usecases_student_components
                        .disabledPrivacyAction,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Policy action',
                    builder: _widgetbook_gallery_usecases_student_components
                        .privacyAction,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'PrivacyPolicyView',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Full offline policy',
                    builder: _widgetbook_gallery_usecases_student_components
                        .privacyPolicy,
                  )
                ],
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'roster',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'AttendanceStatisticsCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Final attendance rate',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .statisticsFinal,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Insufficient historical evidence',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .statisticsUnknown,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Provisional attendance rate',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .statisticsPending,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'DailyRosterView',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Daily attendance roster',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterReady,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Daily performance roster',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterPerformance,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Orphan history',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterOrphan,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Realtime editing and partial saves',
                    builder: _widgetbook_gallery_usecases_roster_live_preview
                        .liveRoster,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Roster empty',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterEmpty,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Roster error',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterError,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Roster loading',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterLoading,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Roster partial save',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterPartial,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Roster saving',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .dailyRosterSaving,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'EnrollmentChangeForm',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Transfer archive and correction',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .enrollmentChange,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'EnrollmentFields',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Enrollment saving',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .enrollmentSaving,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'New enrollment fields',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .enrollmentNew,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Unknown enrollment start',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .enrollmentUnknown,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'PerformanceRecordCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Assessed performance',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .performanceAssessed,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Long performance notes',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .performanceLong,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Readonly performance',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .performanceReadonly,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Unassessed performance',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .performanceUnassessed,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'RecordTextField',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Editable record text',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .recordTextEditable,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Readonly record text',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .recordTextReadonly,
                  ),
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'StudentHistoryView',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'History empty',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .historyEmpty,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'History error',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .historyError,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'History loading',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .historyLoading,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Monthly history and growth',
                    builder: _widgetbook_gallery_usecases_roster_components
                        .historyReady,
                  ),
                ],
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'student_info',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'InfoCardLayoutWith2Column',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Responsive form section',
                    builder: _widgetbook_gallery_usecases_student_components
                        .formSection,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'StudentGrowingReportCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Report rows',
                    builder: _widgetbook_gallery_usecases_student_components
                        .growingReportRows,
                  )
                ],
              ),
              _widgetbook.WidgetbookComponent(
                name: 'StudentIdentityCard',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Card',
                    builder: _widgetbook_gallery_usecases_student_components
                        .identityCard,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Disabled student actions',
                    builder: _widgetbook_gallery_usecases_student_components
                        .identityDisabled,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'List row',
                    builder: _widgetbook_gallery_usecases_student_components
                        .identityRow,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Long content',
                    builder: _widgetbook_gallery_usecases_student_components
                        .identityLong,
                  ),
                ],
              ),
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'yb_dropdown_menu',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'ClassLocationFilterField',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Location filter in header',
                    builder: _widgetbook_gallery_usecases_student_components
                        .locationFilter,
                  )
                ],
              )
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'yellow_ribbon',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'YellowRibbonCountBadge',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Zero and earned ribbons',
                    builder: _widgetbook_gallery_usecases_student_components
                        .ribbonBadges,
                  )
                ],
              )
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'pages',
        children: [
          _widgetbook.WidgetbookFolder(
            name: 'student_detail_page',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'StudentProfileOverview',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Activity error',
                    builder: _widgetbook_gallery_usecases_student_components
                        .profileError,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Empty activity',
                    builder: _widgetbook_gallery_usecases_student_components
                        .profileEmpty,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Loading activity',
                    builder: _widgetbook_gallery_usecases_student_components
                        .profileLoading,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Long motto',
                    builder: _widgetbook_gallery_usecases_student_components
                        .profileLong,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'With activity',
                    builder: _widgetbook_gallery_usecases_student_components
                        .profileReady,
                  ),
                ],
              )
            ],
          ),
          _widgetbook.WidgetbookFolder(
            name: 'student_info_page',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'StudentDirectoryView',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Empty',
                    builder: _widgetbook_gallery_usecases_student_components
                        .directoryEmpty,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Error and retry',
                    builder: _widgetbook_gallery_usecases_student_components
                        .directoryError,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Loading',
                    builder: _widgetbook_gallery_usecases_student_components
                        .directoryLoading,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Search and view switch',
                    builder: _widgetbook_gallery_usecases_student_components
                        .directoryReady,
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    ],
  ),
];
