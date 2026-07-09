//! Minimal GHCR (OCI distribution) client used to pull the WSL rootfs artifact.
//!
//! Only anonymous pull of public artifacts is supported, which is all the
//! launcher needs:
//!   1. fetch an anonymous bearer token,
//!   2. list tags (to resolve "latest"),
//!   3. fetch a manifest and pick the rootfs layer,
//!   4. stream + verify the layer blob.

use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use std::time::Duration;

use anyhow::{anyhow, bail, Context, Result};
use indicatif::{ProgressBar, ProgressStyle};
use reqwest::blocking::Client;
use reqwest::header::{ACCEPT, AUTHORIZATION};
use semver::Version;
use serde::Deserialize;
use sha2::{Digest, Sha256};

use crate::naming::{REGISTRY, REPOSITORY, ROOTFS_MEDIA_TYPE};

const MANIFEST_ACCEPT: &str = concat!(
    "application/vnd.oci.image.index.v1+json,",
    "application/vnd.oci.image.manifest.v1+json,",
    "application/vnd.docker.distribution.manifest.list.v2+json,",
    "application/vnd.docker.distribution.manifest.v2+json"
);

pub struct Registry {
    client: Client,
    token: String,
}

#[derive(Deserialize)]
struct TokenResponse {
    token: String,
}

#[derive(Deserialize)]
struct TagList {
    #[serde(default)]
    tags: Vec<String>,
}

#[derive(Deserialize)]
struct Manifest {
    #[serde(default)]
    layers: Vec<Descriptor>,
    #[serde(default)]
    manifests: Vec<Descriptor>,
}

#[derive(Deserialize, Clone)]
struct Descriptor {
    #[serde(rename = "mediaType")]
    media_type: Option<String>,
    digest: String,
    #[serde(default)]
    size: u64,
}

impl Registry {
    /// Authenticate anonymously for pull access.
    pub fn connect() -> Result<Self> {
        let client = Client::builder()
            .user_agent(concat!("kdlauncher/", env!("CARGO_PKG_VERSION")))
            .timeout(Duration::from_secs(60))
            .build()
            .context("failed to build HTTP client")?;

        let url = format!(
            "https://{REGISTRY}/token?service={REGISTRY}&scope=repository:{REPOSITORY}:pull"
        );
        let token = client
            .get(&url)
            .send()
            .context("failed to request registry token")?
            .error_for_status()
            .context("registry token request rejected")?
            .json::<TokenResponse>()
            .context("failed to parse registry token response")?
            .token;

        Ok(Self { client, token })
    }

    /// Resolve the highest semver `v*` tag available in the repository.
    pub fn latest_version(&self) -> Result<String> {
        let url = format!("https://{REGISTRY}/v2/{REPOSITORY}/tags/list");
        let tags = self
            .client
            .get(&url)
            .header(AUTHORIZATION, format!("Bearer {}", self.token))
            .send()
            .context("failed to list tags")?
            .error_for_status()
            .context("tag list request rejected")?
            .json::<TagList>()
            .context("failed to parse tag list")?
            .tags;

        latest_semver(&tags)
            .ok_or_else(|| anyhow!("no versioned tags found in {REGISTRY}/{REPOSITORY}"))
    }

    /// Download and verify the rootfs tarball for `version` into `dest`.
    /// Returns the resolved layer digest.
    pub fn download_rootfs(&self, version: &str, dest: &Path) -> Result<String> {
        let tag = crate::naming::tag_for(version);
        let layer = self.resolve_rootfs_layer(&tag)?;

        let url = format!("https://{REGISTRY}/v2/{REPOSITORY}/blobs/{}", layer.digest);
        let mut response = self
            .client
            .get(&url)
            .header(AUTHORIZATION, format!("Bearer {}", self.token))
            .send()
            .context("failed to request rootfs blob")?
            .error_for_status()
            .context("rootfs blob request rejected")?;

        let progress = new_progress(layer.size);
        let mut file =
            File::create(dest).with_context(|| format!("failed to create {}", dest.display()))?;
        let mut hasher = Sha256::new();
        let mut buf = [0u8; 64 * 1024];
        loop {
            let n = response
                .read(&mut buf)
                .context("error reading blob stream")?;
            if n == 0 {
                break;
            }
            hasher.update(&buf[..n]);
            file.write_all(&buf[..n])
                .context("error writing rootfs to disk")?;
            progress.inc(n as u64);
        }
        progress.finish_and_clear();

        let actual = format!("sha256:{:x}", hasher.finalize());
        if actual != layer.digest {
            bail!("digest mismatch: expected {}, got {actual}", layer.digest);
        }
        Ok(layer.digest)
    }

    fn resolve_rootfs_layer(&self, reference: &str) -> Result<Descriptor> {
        let manifest = self.fetch_manifest(reference)?;

        // If this is an image index, follow the first sub-manifest.
        let manifest = if manifest.layers.is_empty() && !manifest.manifests.is_empty() {
            let child = &manifest.manifests[0];
            self.fetch_manifest(&child.digest)?
        } else {
            manifest
        };

        if manifest.layers.is_empty() {
            bail!("manifest {reference} contains no layers");
        }

        // Prefer the layer with our custom media type; fall back to the largest.
        let layer = manifest
            .layers
            .iter()
            .find(|l| l.media_type.as_deref() == Some(ROOTFS_MEDIA_TYPE))
            .cloned()
            .or_else(|| manifest.layers.iter().max_by_key(|l| l.size).cloned())
            .ok_or_else(|| anyhow!("no usable rootfs layer in manifest {reference}"))?;

        Ok(layer)
    }

    fn fetch_manifest(&self, reference: &str) -> Result<Manifest> {
        let url = format!("https://{REGISTRY}/v2/{REPOSITORY}/manifests/{reference}");
        self.client
            .get(&url)
            .header(AUTHORIZATION, format!("Bearer {}", self.token))
            .header(ACCEPT, MANIFEST_ACCEPT)
            .send()
            .with_context(|| format!("failed to fetch manifest {reference}"))?
            .error_for_status()
            .with_context(|| format!("manifest {reference} not found"))?
            .json::<Manifest>()
            .with_context(|| format!("failed to parse manifest {reference}"))
    }
}

fn latest_semver(tags: &[String]) -> Option<String> {
    tags.iter()
        .filter_map(|t| t.strip_prefix('v'))
        .filter_map(|v| Version::parse(v).ok().map(|parsed| (parsed, v.to_owned())))
        .max_by(|a, b| a.0.cmp(&b.0))
        .map(|(_, v)| v)
}

fn new_progress(total: u64) -> ProgressBar {
    let pb = ProgressBar::new(total.max(1));
    pb.set_style(
        ProgressStyle::with_template("  {bar:40.cyan/blue} {bytes}/{total_bytes} ({eta}) {msg}")
            .unwrap_or_else(|_| ProgressStyle::default_bar())
            .progress_chars("=> "),
    );
    pb.set_message("downloading rootfs");
    pb
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn picks_highest_semver_tag() {
        let tags = vec![
            "v1.0.0".to_string(),
            "v1.2.3".to_string(),
            "v1.10.0".to_string(),
            "latest".to_string(),
            "not-a-version".to_string(),
        ];
        assert_eq!(latest_semver(&tags).as_deref(), Some("1.10.0"));
    }

    #[test]
    fn returns_none_without_versioned_tags() {
        let tags = vec!["latest".to_string(), "edge".to_string()];
        assert_eq!(latest_semver(&tags), None);
    }
}
