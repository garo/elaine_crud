# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-22

Initial release of ElaineCrud - a Rails engine for rapidly generating CRUD interfaces.

### Features

- **Zero-configuration CRUD**: Automatic index, show, new, edit, and delete actions for any ActiveRecord model
- **Flexible field configuration DSL**: Customize field titles, descriptions, and display formatting
- **Foreign key support**: Automatic display of related records with configurable formatting and auto-linking
- **Has-many relationships**: Automatic display of associated records with counts and links
- **HABTM support**: Display and manage has_and_belongs_to_many associations
- **Nested resource creation**: Create related records via modal dialogs without leaving the form
- **Pagination**: Built-in pagination with Kaminari
- **Export functionality**: Export data to Excel (XLSX) and CSV formats
- **Custom layouts**: Two-dimensional grid layouts with colspan/rowspan support
- **Modern UI**: Clean, responsive interface built with TailwindCSS and Turbo
- **Extensible**: Override views, helpers, and controller methods in host application

### Technical Details

- Rails 6.0+ support
- Non-mountable engine design for seamless integration
- Turbo Frames for modal loading
- Turbo Streams for dynamic UI updates
- Comprehensive test coverage with RSpec and Capybara

[0.1.0]: https://github.com/garo/elaine_crud/releases/tag/v0.1.0
