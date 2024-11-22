# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit edo desktop

# just a bandaid. we can actually fix it if ghostty releases before zig eclass is merged.
#REQUIRE="network-sandbox"
DESCRIPTION="Fast, native, feature-rich terminal emulator pushing modern features."
HOMEPAGE="https://github.com/ghostty-org/ghostty"
SRC_URI="ghostty-source.tar.gz"
S="${WORKDIR}"
LICENSE=""

SLOT="0"

IUSE="+gtk doc helpgen bench test-exe"

EZIG_MIN="0.13"
EZIG_MAX_EXCLUSIVE="0.14"

DEPEND="
	app-arch/bzip2
	media-libs/fontconfig
	media-libs/freetype
	gui-libs/gtk
	media-libs/harfbuzz
	gtk? ( gui-libs/libadwaita )
	media-libs/libpng
	dev-libs/oniguruma
	x11-libs/pixman
	sys-libs/zlib
"
#RDEPEND="${DEPEND}"
BDEPEND="
	|| ( dev-lang/zig-bin:${EZIG_MIN} dev-lang/zig:${EZIG_MIN} )
	doc? ( app-text/pandoc )
"

zig-set_EZIG() {
	[[ -n ${EZIG} ]] && return
	if [[ -n ${EZIG_OVERWRITE} ]]; then
		export EZIG="${EZIG_OVERWRITE}"
		return
	fi
	local candidate selected selected_ver ver
	for candidate in "${BROOT}"/usr/bin/zig-*; do
		if [[ ! -L ${candidate} || ${candidate} != */zig?(-bin)-+([0-9.]) ]]; then
			continue
		fi
		ver=${candidate##*-}
		if [[ -n ${EZIG_EXACT_VER} ]]; then
			ver_test "${ver}" -ne "${EZIG_EXACT_VER}" && continue
			selected="${candidate}"
			selected_ver="${ver}"
			break
		fi
		if [[ -n ${EZIG_MIN} ]] \
			&& ver_test "${ver}" -lt "${EZIG_MIN}"; then
			# Candidate does not satisfy EZIG_MIN condition.
			continue
		fi
		if [[ -n ${EZIG_MAX_EXCLUSIVE} ]] \
			&& ver_test "${ver}" -ge "${EZIG_MAX_EXCLUSIVE}"; then
			# Candidate does not satisfy EZIG_MAX_EXCLUSIVE condition.
			continue
		fi
		if [[ -n ${selected_ver} ]] \
			&& ver_test "${selected_ver}" -gt "${ver}"; then
			# Candidate is older than the currently selected candidate.
			continue
		fi
		selected="${candidate}"
		selected_ver="${ver}"
	done
	if [[ -z ${selected} ]]; then
		die "Could not find (suitable) zig installation in ${BROOT}/usr/bin"
	fi
	export EZIG="${selected}"
	export EZIG_VER="${selected_ver}"
}

ezig() {
	zig-set_EZIG
	edo "${EZIG}" "${@}"
}

src_configure() {
	export ZBS_ARGS=(
		-Doptimize=ReleaseFast
		-Dgtk-adwaita=$(usex gtk true false)
		-Demit-docs=$(usex doc true false)
		-Demit-helpgen=$(usex helpgen true false)
		-Demit-bench=$(usex bench true false)
		-Demit-test-exe=$(usex test-exe true false)
	)
}

src_compile() {
	ezig build "${ZBS_ARGS[@]}" --prefix "${T}/temp_install" || die
}

src_test() {
	ezig build test "${ZBS_ARGS[@]}" --prefix "${T}/temp_install" || die
}

src_install() {
	ezig build install "${ZBS_ARGS[@]}" --prefix "${ED}/usr" || die

	domenu dist/linux/app.desktop
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	xdg_icon_cache_update
}
