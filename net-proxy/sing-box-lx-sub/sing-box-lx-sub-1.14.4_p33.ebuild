# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd shell-completion git-r3

MY_PV="${PV%%_p*}-lx-sub.${PV##*_p}"

EGIT_REPO_URI="https://github.com/whistooy/sing-box-lx-sub.git"
EGIT_COMMIT="v${MY_PV}"

EGIT_SUBMODULES=(
	submodules/gvisor
	submodules/sing-tun
	submodules/utls
	submodules/wireguard-go
)

DESCRIPTION="Universal proxy platform (Leadaxe lx fork with in-core providers)"
HOMEPAGE="https://github.com/whistooy/sing-box-lx-sub"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~riscv"

# Build tags: https://sing-box.sagernet.org/installation/build-from-source/#build-tags
# Differences from upstream: naive disabled by default; no embedded tor/ebpf;
# extra lx tags: awg, lx-chain, lxd, trusttunnel, xhttp.
IUSE="
	+acme +awg +ccm +clash-api +cloudflared +dhcp grpc +gvisor +lx-chain
	+lxd naive +ocm +openconnect +openvpn +quic +tailscale +trusttunnel
	+usbip +utls v2ray-api +wireguard +xhttp
"
REQUIRED_USE="awg? ( wireguard )"

RDEPEND="
	acct-group/sing-box
	acct-user/sing-box
"
BDEPEND=">=dev-lang/go-1.26.0"

src_unpack() {
	git-r3_src_unpack
	go-module_live_vendor
}

src_compile() {
	local mytags="badlinkname,tfogo_checklinkname0,"
	use acme && mytags+="with_acme,"
	use awg && mytags+="with_awg,"
	use ccm && mytags+="with_ccm,"
	use clash-api && mytags+="with_clash_api,"
	use cloudflared && mytags+="with_cloudflared,"
	use dhcp && mytags+="with_dhcp,"
	use grpc && mytags+="with_grpc,"
	use gvisor && mytags+="with_gvisor,"
	use lx-chain && mytags+="with_lx_chain,"
	use lxd && mytags+="with_lxd,with_lx_command,"
	use naive && mytags+="with_purego,with_naive_outbound,"
	use ocm && mytags+="with_ocm,"
	use openconnect && mytags+="with_openconnect,"
	use openvpn && mytags+="with_openvpn,"
	use quic && mytags+="with_quic,"
	use tailscale && mytags+="with_tailscale,"
	use trusttunnel && mytags+="with_trusttunnel,"
	use usbip && mytags+="with_usbip,"
	use utls && mytags+="with_utls,"
	use v2ray-api && mytags+="with_v2ray_api,"
	use wireguard && mytags+="with_wireguard,"
	use xhttp && mytags+="with_xhttp,"

	ego build -trimpath -tags "${mytags%,}" \
		-ldflags "-X 'github.com/sagernet/sing-box/constant.Version=${MY_PV}' -checklinkname=0 -buildid=" \
		./cmd/sing-box

	mkdir completions
	./sing-box completion bash > completions/sing-box
	./sing-box completion fish > completions/sing-box.fish
	./sing-box completion zsh > completions/_sing-box
}

src_install() {
	dobin sing-box

	insinto /etc/sing-box
	newins release/config/config.json config.json.example

	newinitd release/config/sing-box.initd sing-box
	newconfd release/config/sing-box.confd sing-box
	systemd_dounit release/config/sing-box.service

	insinto /usr/share/polkit-1/rules.d
	doins release/config/sing-box.rules

	dobashcomp completions/sing-box
	dofishcomp completions/sing-box.fish
	dozshcomp completions/_sing-box
}
