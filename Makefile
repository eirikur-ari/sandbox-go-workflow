# dummy Makefile

BINARY_NAME := dummy
BUILD_DIR := build
BIN_DIR := bin
DIST_DIR := $(BUILD_DIR)/dist

DEVCONTAINER := bash scripts/devcontainer.sh

## help: Show this help
.PHONY: help
help:
	@echo "Usage: make [task]"
	@echo ""
	@sed -n 's/^## //p' $(MAKEFILE_LIST) | column -t -s ':' | sed 's/^/  /'

## all: Run every task
.PHONY: all
all: clean vet fmt-lint test coverage coverage-html build test-acceptance

## vet: Run go vet on all packages, including the integration and acceptance tests
.PHONY: vet
vet:
	go vet -tags "integration acceptance" ./...

## lint: Run all non-mutating source and dependency checks
.PHONY: lint
lint: fmt-lint

## fmt-lint: Check source code is formatted, without changing anything
.PHONY: fmt-lint
fmt-lint:
	@echo "Checking source formatting"
	@unformatted=$$(gofmt -l .); \
	if [ -n "$$unformatted" ]; then \
		echo "The following files are not gofmt-formatted:"; \
		echo "$$unformatted"; \
		exit 1; \
	fi

## build: Compile the binary
.PHONY: build
build:
	bash scripts/build.sh host

## build-all: Compile the binary for every release platform, optionally stamped with a release version
.PHONY: build-all
build-all:
	bash scripts/build.sh all

## test: Run the tests
.PHONY: test
test:
	@echo "Running tests..."
	go test -v -tags integration -race -count=1 ./...

## test-acceptance: Run the acceptance tests
.PHONY: test-acceptance
## test-acceptance: Run only acceptance tests against the built binary, failing if it does not exist
.PHONY: test-acceptance
test-acceptance:
	bash scripts/acceptance-test.sh run

## coverage: Run unit and integration tests with the race detector, then print a function coverage report
.PHONY: coverage
coverage:
	@mkdir -p $(BUILD_DIR)
	go test -v -tags integration -race -count=1 -coverprofile=$(BUILD_DIR)/coverage.out -covermode=atomic ./...
	go tool cover -func=$(BUILD_DIR)/coverage.out

## coverage-summary: Print the total coverage percentage of an existing coverage profile
.PHONY: coverage-summary
coverage-summary:
	@go tool cover -func=$(BUILD_DIR)/coverage.out | awk '/^total:/ {print $$3}'

## coverage-html: Generate an HTML report from an existing coverage profile
.PHONY: coverage-html
coverage-html:
	go tool cover -html=$(BUILD_DIR)/coverage.out -o $(BUILD_DIR)/coverage.html

## licenses: Collect the licenses of the third-party software compiled into the binary
.PHONY: licenses
licenses:
	bash scripts/third-party-licenses.sh

## package: Package the binary and related files into a tar.gz archive
.PHONY: package
package:
	bash scripts/package.sh

## checksums: Write the SHA-256 checksums of the release archives
.PHONY: checksums
checksums:
	cd $(DIST_DIR) && shasum -a 256 *.tar.gz > checksums.txt

## changelog-version: Print the version of the latest release in the changelog
.PHONY: changelog-version
changelog-version:
	@bash scripts/changelog-version.sh

## changelog-unreleased: Print the entries of the Unreleased section of the changelog
.PHONY: changelog-unreleased
changelog-unreleased:
	@bash scripts/changelog-unreleased.sh

## release-notes: Write the release notes of a version from the changelog to a file, then print them
.PHONY: release-notes
release-notes: release-notes-file
	cat $(BUILD_DIR)/release-notes.md

## release-notes-content: Print the release notes of a version from the changelog, failing if there are none
.PHONY: release-notes-content
release-notes-content:
	bash scripts/release-notes.sh

## release-notes-file: Write the release notes of a version from the changelog to a file, failing if there are none
.PHONY: release-notes-file
release-notes-file:
	@mkdir -p $(BUILD_DIR)
	bash scripts/release-notes.sh > $(BUILD_DIR)/release-notes.md || { rm -f $(BUILD_DIR)/release-notes.md; exit 1; }

## clean: Remove build artifacts
.PHONY: clean
clean:
	@echo "Running clean..."
	@rm -rf $(BIN_DIR) $(BUILD_DIR)

## dev-start: Start the devcontainer
.PHONY: dev-start
dev-start:
	@$(DEVCONTAINER) start

## dev-rebuild: Rebuild the devcontainer from scratch
.PHONY: dev-rebuild
dev-rebuild:
	@$(DEVCONTAINER) rebuild

## dev-stop: Stop the devcontainer
.PHONY: dev-stop
dev-stop:
	@$(DEVCONTAINER) stop

## dev-shell: Open a shell in the devcontainer
.PHONY: dev-shell
dev-shell:
	@$(DEVCONTAINER) shell

## dev-copy: Copy a file or directory into the devcontainer
.PHONY: dev-copy
dev-copy:
	$(DEVCONTAINER) copy "$(SOURCE)" $(if $(DESTINATION),"$(DESTINATION)")

## dev-destroy: Remove the devcontainer and its image
.PHONY: dev-destroy
dev-destroy:
	@$(DEVCONTAINER) destroy

## dev-status: Show the status of the devcontainer
.PHONY: dev-status
dev-status:
	@$(DEVCONTAINER) status