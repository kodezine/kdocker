//! Naming conventions shared across the launcher.
//!
//! A kdocker version `1.2.3` maps to:
//!   * WSL distribution name : `kdocker-wsl-v1.2.3`
//!   * GHCR artifact tag      : `v1.2.3`

/// Prefix shared by every kdocker WSL distribution name.
pub const DISTRO_PREFIX: &str = "kdocker-wsl-v";

/// GHCR registry host.
pub const REGISTRY: &str = "ghcr.io";

/// GHCR repository holding the WSL rootfs artifacts.
pub const REPOSITORY: &str = "kodezine/kdocker-wsl";

/// Custom media type used for the rootfs layer pushed via `oras`.
pub const ROOTFS_MEDIA_TYPE: &str = "application/vnd.kdocker.wsl.rootfs.v1.tar+gzip";

/// WSL distribution name for a given version, e.g. `kdocker-wsl-v1.2.3`.
pub fn distro_name(version: &str) -> String {
    format!("{DISTRO_PREFIX}{version}")
}

/// Extract the version from a kdocker distribution name, if it is one.
pub fn version_from_distro(distro: &str) -> Option<String> {
    distro
        .strip_prefix(DISTRO_PREFIX)
        .filter(|v| !v.is_empty())
        .map(str::to_owned)
}

/// GHCR tag for a given version, e.g. `v1.2.3`.
pub fn tag_for(version: &str) -> String {
    format!("v{version}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn distro_name_prefixes_version() {
        assert_eq!(distro_name("1.2.3"), "kdocker-wsl-v1.2.3");
    }

    #[test]
    fn version_from_distro_roundtrips() {
        assert_eq!(
            version_from_distro("kdocker-wsl-v1.2.3"),
            Some("1.2.3".into())
        );
    }

    #[test]
    fn version_from_distro_rejects_non_kdocker() {
        assert_eq!(version_from_distro("Ubuntu"), None);
        assert_eq!(version_from_distro("kdocker-wsl-v"), None);
    }

    #[test]
    fn tag_prefixes_v() {
        assert_eq!(tag_for("2.0.0"), "v2.0.0");
    }
}
