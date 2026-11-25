# Every target that is not an aggregate runs the task of the same name from scripts/tasks, through the task dispatcher.
# The order of the tasks is declared here, as prerequisites, and an aggregate only runs its prerequisites.
# The descriptions of the tasks are printed by make help. Variables given on the command line, such as make dev-copy SOURCE=file,
# reach the task as environment variables.

.PHONY: help
help: ; @bash scripts/task.sh help

# Aggregates
.PHONY: all lint
all: clean vet fmt-lint test coverage coverage-html build package acceptance-test
lint: vet fmt-lint

# Build and package
.PHONY: clean build build-all package package-all checksums licenses
clean: ; @bash scripts/task.sh clean
build: ; @bash scripts/task.sh build
build-all: ; @bash scripts/task.sh build-all
package-all: build-all ; @bash scripts/task.sh package-all
package: build ; @bash scripts/task.sh package
checksums: package-all ; @bash scripts/task.sh checksums
licenses: ; @bash scripts/task.sh licenses

# Check and test
.PHONY: vet fmt-lint test coverage coverage-summary coverage-html acceptance-extract acceptance-test readme-lint-go-badge readme-lint-release-badge
vet: ; @bash scripts/task.sh vet
fmt-lint: ; @bash scripts/task.sh fmt-lint
test: ; @bash scripts/task.sh test
coverage: ; @bash scripts/task.sh coverage
coverage-summary: ; @bash scripts/task.sh coverage-summary
coverage-html: ; @bash scripts/task.sh coverage-html
acceptance-extract: package ; @bash scripts/task.sh acceptance-extract
acceptance-test: acceptance-extract ; @bash scripts/task.sh acceptance-test
readme-lint-go-badge: ; @bash scripts/task.sh readme-lint-go-badge
readme-lint-release-badge: ; @bash scripts/task.sh readme-lint-release-badge

# Changelog and release
.PHONY: changelog-version changelog-unreleased release-notes release-notes-content release-notes-file resolve-version check-version-format check-branch check-tag check-changelog check-release-notes
changelog-version: ; @bash scripts/task.sh changelog-version
changelog-unreleased: ; @bash scripts/task.sh changelog-unreleased
release-notes: release-notes-file ; @bash scripts/task.sh release-notes
release-notes-content: ; @bash scripts/task.sh release-notes-content
release-notes-file: ; @bash scripts/task.sh release-notes-file
resolve-version: ; @bash scripts/task.sh resolve-version
check-version-format: ; @bash scripts/task.sh check-version-format
check-branch: ; @bash scripts/task.sh check-branch
check-tag: ; @bash scripts/task.sh check-tag
check-changelog: ; @bash scripts/task.sh check-changelog
check-release-notes: ; @bash scripts/task.sh check-release-notes

# Devcontainer
.PHONY: dev-start dev-rebuild dev-stop dev-shell dev-copy dev-destroy dev-status
dev-start: ; @bash scripts/task.sh dev-start
dev-rebuild: ; @bash scripts/task.sh dev-rebuild
dev-stop: ; @bash scripts/task.sh dev-stop
dev-shell: ; @bash scripts/task.sh dev-shell
dev-copy: ; @bash scripts/task.sh dev-copy
dev-destroy: ; @bash scripts/task.sh dev-destroy
dev-status: ; @bash scripts/task.sh dev-status
