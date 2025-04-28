# Naming Standardization Guide for Concursos IA Project

This guide establishes standards for naming files, classes, and methods in the Concursos IA project, aiming to maintain consistency and facilitate maintenance.

## General Principles

1. **Language**: All new files, classes, and methods should be named in English.
2. **Accents**: Do not use accents or special characters in file names.
3. **Separation**: Use underscore (\_) to separate words in file names.
4. **Capitalization**: Follow the camelCase pattern for variables and methods, PascalCase for classes.

## File Naming Patterns

### Services

- Format: `[functionality]_service.dart`
- Examples:
  - `auth_service.dart`
  - `theme_service.dart`
  - `analytics_service.dart`

### Utilities

- Format: `[functionality]_util.dart` or `[functionality]_utils.dart`
- Examples:
  - `text_utils.dart`
  - `text_formatter.dart`
  - `cache_manager.dart`

### Screens

- Format: `[functionality]_screen.dart`
- Examples:
  - `login_screen.dart`
  - `register_screen.dart`
  - `settings_screen.dart`

### Models

- Format: `[entity]_model.dart`
- Examples:
  - `user_model.dart`
  - `exam_notice_model.dart`

### Widgets

- Format: `[functionality]_widget.dart`
- Examples:
  - `custom_button_widget.dart`
  - `exam_notice_card_widget.dart`

## Class Naming Patterns

### Services

- Format: `[Functionality]Service`
- Examples:
  - `AuthService`
  - `ThemeService`

### Utilities

- Format: `[Functionality]Utils` or `[Functionality]Util`
- Examples:
  - `TextUtils`
  - `TextFormatter`

### Screens

- Format: `[Functionality]Screen`
- Examples:
  - `LoginScreen`
  - `RegisterScreen`

### Models

- Format: `[Entity]Model`
- Examples:
  - `UserModel`
  - `ExamNoticeModel`

### Widgets

- Format: `[Functionality]Widget`
- Examples:
  - `CustomButtonWidget`
  - `ExamNoticeCardWidget`