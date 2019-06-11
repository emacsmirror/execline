export LC_ALL=C

# This package is maintained with cask: https://github.com/cask/cask;
# executable can be run right out of the git clone. It provides support for fetching
# and upgrading dependencies.
#
# This support is imperfect (no support for local mirrors), but it still better, then
# writing own hacks to re-use ~/.emacs.d/elpa.

# Install dependencies, specified in ./Cask. This target is not dependency of "check",
# since it requires network access.
prepare:
	cask install
check:
	cask emacs --batch --quick --load t/indent.el --funcall ert-run-tests-batch-and-exit
.PHONY: check
