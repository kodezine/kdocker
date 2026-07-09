//! Reading, writing, and locating the `kdocker-version.json` manifest.

use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{bail, Context, Result};
use serde::{Deserialize, Serialize};

use crate::config::Paths;

const MANIFEST_FILENAME: &str = "kdocker-version.json";

/// The declarative desired state: which kdocker versions should be installed.
#[derive(Debug, Default, Serialize, Deserialize)]
pub struct Manifest {
    #[serde(default)]
    pub versions: Vec<String>,
}

impl Manifest {
    pub fn load(path: &Path) -> Result<Self> {
        let bytes = fs::read(path)
            .with_context(|| format!("failed to read manifest {}", path.display()))?;
        let manifest: Manifest = serde_json::from_slice(&bytes)
            .with_context(|| format!("failed to parse manifest {}", path.display()))?;
        Ok(manifest)
    }

    pub fn save(&self, path: &Path) -> Result<()> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("failed to create {}", parent.display()))?;
        }
        let json = serde_json::to_string_pretty(self)?;
        fs::write(path, format!("{json}\n"))
            .with_context(|| format!("failed to write manifest {}", path.display()))
    }

    /// Deduplicated, order-preserving list of versions.
    pub fn unique_versions(&self) -> Vec<String> {
        let mut seen = std::collections::BTreeSet::new();
        self.versions
            .iter()
            .filter(|v| seen.insert((*v).clone()))
            .cloned()
            .collect()
    }
}

/// Outcome of locating a manifest.
pub enum Resolved {
    /// An existing manifest was found at this path.
    Found(PathBuf, Manifest),
    /// No manifest was found; this is the default path to create.
    Missing(PathBuf),
}

/// Locate the manifest by precedence:
///   1. explicit `--manifest` path (must exist),
///   2. `kdocker-version.json` next to the executable,
///   3. `%USERPROFILE%\.kdocker\kdocker-version.json` (default).
pub fn resolve(explicit: Option<&Path>, paths: &Paths) -> Result<Resolved> {
    if let Some(path) = explicit {
        if !path.exists() {
            bail!("manifest not found: {}", path.display());
        }
        let manifest = Manifest::load(path)?;
        return Ok(Resolved::Found(path.to_path_buf(), manifest));
    }

    if let Some(next_to_exe) = exe_sibling_manifest() {
        if next_to_exe.exists() {
            let manifest = Manifest::load(&next_to_exe)?;
            return Ok(Resolved::Found(next_to_exe, manifest));
        }
    }

    if paths.default_manifest.exists() {
        let manifest = Manifest::load(&paths.default_manifest)?;
        return Ok(Resolved::Found(paths.default_manifest.clone(), manifest));
    }

    Ok(Resolved::Missing(paths.default_manifest.clone()))
}

fn exe_sibling_manifest() -> Option<PathBuf> {
    let exe = std::env::current_exe().ok()?;
    Some(exe.parent()?.join(MANIFEST_FILENAME))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unique_versions_dedupes_preserving_order() {
        let m = Manifest {
            versions: vec!["1.0.0".into(), "2.0.0".into(), "1.0.0".into()],
        };
        assert_eq!(m.unique_versions(), vec!["1.0.0", "2.0.0"]);
    }

    #[test]
    fn parses_versions_array() {
        let m: Manifest = serde_json::from_str(r#"{"versions":["1.2.3","1.1.0"]}"#).unwrap();
        assert_eq!(m.versions, vec!["1.2.3", "1.1.0"]);
    }

    #[test]
    fn missing_versions_defaults_empty() {
        let m: Manifest = serde_json::from_str("{}").unwrap();
        assert!(m.versions.is_empty());
    }
}
