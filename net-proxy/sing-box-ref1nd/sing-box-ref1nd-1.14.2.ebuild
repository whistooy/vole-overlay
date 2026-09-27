# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-env go-module systemd shell-completion git-r3

EGIT_REPO_URI="https://github.com/reF1nd/sing-box.git"
EGIT_COMMIT="v${PV}-reF1nd"

DESCRIPTION="The universal proxy platform (reF1nd fork)"
HOMEPAGE="https://sing-box.sagernet.org/ https://github.com/reF1nd/sing-box"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~riscv"

# Build tags: https://sing-box.sagernet.org/installation/build-from-source/#build-tags
# Defaults: https://github.com/reF1nd/sing-box/blob/reF1nd-stable/release/DEFAULT_BUILD_TAGS
# Differences from upstream: no embedded tor, extra with_ebpf.
IUSE="
	+acme +ccm +clash-api +cloudflared +dhcp ebpf grpc +gvisor naive +ocm
	+openconnect +openvpn +quic +tailscale +usbip +utls v2ray-api +wireguard
"

RDEPEND="
	acct-group/sing-box
	acct-user/sing-box
	!net-proxy/sing-box
"
BDEPEND=">=dev-lang/go-1.25.5"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	local mytags
	use acme && mytags+="with_acme,"
	use ccm && mytags+="with_ccm,"
	use clash-api && mytags+="with_clash_api,"
	use cloudflared && mytags+="with_cloudflared,"
	use dhcp && mytags+="with_dhcp,"
	use ebpf && mytags+="with_ebpf,"
	use grpc && mytags+="with_grpc,"
	use gvisor && mytags+="with_gvisor,"
	use naive && mytags+="with_purego,with_naive_outbound,"
	use ocm && mytags+="with_ocm,"
	use openconnect && mytags+="with_openconnect,"
	use openvpn && mytags+="with_openvpn,"
	use quic && mytags+="with_quic,"
	use tailscale && mytags+="with_tailscale,"
	use usbip && mytags+="with_usbip,"
	use utls && mytags+="with_utls,"
	use v2ray-api && mytags+="with_v2ray_api,"
	use wireguard && mytags+="with_wireguard,"

	ego build -trimpath -tags "${mytags%,}" \
		-ldflags "-X 'github.com/sagernet/sing-box/constant.Version=${PV}' -checklinkname=0 -buildid=" \
		./cmd/sing-box

	mkdir completions
	./sing-box completion bash > completions/sing-box
	./sing-box completion fish > completions/sing-box.fish
	./sing-box completion zsh > completions/_sing-box
}

src_install() {
	if ! use naive; then
		dobin sing-box
	else
		insinto /usr/lib/sing-box
		doins sing-box "vendor/github.com/sagernet/cronet-go/lib/linux_$(go-env_goarch)/libcronet.so"
		dosym ../lib/sing-box/sing-box /usr/bin/sing-box
		fperms +x /usr/bin/sing-box /usr/lib/sing-box/sing-box
	fi

	insinto /etc/sing-box
	newins release/config/config.json config.json.example

	newinitd release/config/sing-box.initd sing-box
	systemd_dounit release/config/sing-box{,@}.service

	insinto /usr/share/dbus-1/system.d
	newins release/config/sing-box-split-dns.xml sing-box-dns.conf

	insinto /usr/share/polkit-1/rules.d
	doins release/config/sing-box.rules

	dobashcomp completions/sing-box
	dofishcomp completions/sing-box.fish
	dozshcomp completions/_sing-box
}
