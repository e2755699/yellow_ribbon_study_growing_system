// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _i1;
import 'package:widgetbook_gallery/usecases/design_system.dart' as _i2;
import 'package:widgetbook_gallery/usecases/student_components.dart' as _i3;

final directories = <_i1.WidgetbookNode>[
  _i1.WidgetbookFolder(
    name: 'design_system',
    children: [
      _i1.WidgetbookFolder(
        name: 'presentation',
        children: [
          _i1.WidgetbookLeafComponent(
            name: 'DesignSystemDashboard',
            useCase: _i1.WidgetbookUseCase(
              name: 'Theme Settings',
              builder: _i2.themeSettings,
            ),
          ),
          _i1.WidgetbookLeafComponent(
            name: 'DesignSystemPreview',
            useCase: _i1.WidgetbookUseCase(
              name: 'Four palettes · Light & Dark',
              builder: _i2.palettes,
            ),
          ),
          _i1.WidgetbookFolder(
            name: 'components',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'SystemPage',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Directory to profile journey',
                  builder: _i3.studentJourney,
                ),
              ),
              _i1.WidgetbookLeafComponent(
                name: 'SystemSectionCard',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Section and actions',
                  builder: _i3.sectionCard,
                ),
              ),
            ],
          ),
        ],
      )
    ],
  ),
  _i1.WidgetbookFolder(
    name: 'main',
    children: [
      _i1.WidgetbookFolder(
        name: 'components',
        children: [
          _i1.WidgetbookFolder(
            name: 'avatar',
            children: [
              _i1.WidgetbookComponent(
                name: 'StudentAvatar',
                useCases: [
                  _i1.WidgetbookUseCase(
                    name: 'Default boy and girl',
                    builder: _i3.avatarDefaults,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Loading photo',
                    builder: _i3.avatarLoading,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Missing photo and retry',
                    builder: _i3.avatarError,
                  ),
                ],
              )
            ],
          ),
          _i1.WidgetbookFolder(
            name: 'student_info',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'InfoCardLayoutWith2Column',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Responsive form section',
                  builder: _i3.formSection,
                ),
              ),
              _i1.WidgetbookComponent(
                name: 'StudentIdentityCard',
                useCases: [
                  _i1.WidgetbookUseCase(
                    name: 'Card',
                    builder: _i3.identityCard,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'List row',
                    builder: _i3.identityRow,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Long content',
                    builder: _i3.identityLong,
                  ),
                ],
              ),
            ],
          ),
          _i1.WidgetbookFolder(
            name: 'yellow_ribbon',
            children: [
              _i1.WidgetbookLeafComponent(
                name: 'YellowRibbonCountBadge',
                useCase: _i1.WidgetbookUseCase(
                  name: 'Zero and earned ribbons',
                  builder: _i3.ribbonBadges,
                ),
              )
            ],
          ),
        ],
      ),
      _i1.WidgetbookFolder(
        name: 'pages',
        children: [
          _i1.WidgetbookFolder(
            name: 'student_detail_page',
            children: [
              _i1.WidgetbookComponent(
                name: 'StudentProfileOverview',
                useCases: [
                  _i1.WidgetbookUseCase(
                    name: 'Activity error',
                    builder: _i3.profileError,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Empty activity',
                    builder: _i3.profileEmpty,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Loading activity',
                    builder: _i3.profileLoading,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Long motto',
                    builder: _i3.profileLong,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'With activity',
                    builder: _i3.profileReady,
                  ),
                ],
              )
            ],
          ),
          _i1.WidgetbookFolder(
            name: 'student_info_page',
            children: [
              _i1.WidgetbookComponent(
                name: 'StudentDirectoryView',
                useCases: [
                  _i1.WidgetbookUseCase(
                    name: 'Empty',
                    builder: _i3.directoryEmpty,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Error and retry',
                    builder: _i3.directoryError,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Loading',
                    builder: _i3.directoryLoading,
                  ),
                  _i1.WidgetbookUseCase(
                    name: 'Search and view switch',
                    builder: _i3.directoryReady,
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
