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
