//! Filesystem paths and persisted installation state.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use directories::BaseDirs;
use serde::{Deserialize, Serialize};

/// Resolved launcher paths.
pub struct Paths {
    /// Directory holding imported distributions (`%LOCALAPPDATA%\kdocker\distros`).
    pub distros_dir: PathBuf,
    /// Persisted state file (`%LOCALAPPDATA%\kdocker\state.json`).
    pub state_file: PathBuf,
    /// Default manifest path (`%USERPROFILE%\.kdocker\kdocker-version.json`).
    pub default_manifest: PathBuf,
}

impl Paths {
    pub fn resolve() -> Result<Self> {
        let base = BaseDirs::new().context("unable to determine user directories")?;
        let data_dir = base.data_local_dir().join("kdocker");
        let distros_dir = data_dir.join("distros");
        let state_file = data_dir.join("state.json");
        let default_manifest = base
            .home_dir()
            .join(".kdocker")
            .join("kdocker-version.json");
        Ok(Self {
            distros_dir,
            state_file,
            default_manifest,
        })
    }

    /// Install directory for a specific version.
    pub fn install_dir(&self, version: &str) -> PathBuf {
        self.distros_dir.join(version)
    }
}

/// Metadata recorded for an installed distribution.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstalledEntry {
    pub distro: String,
    pub install_dir: PathBuf,
    pub digest: String,
}

/// Persisted launcher state, keyed by version.
#[derive(Debug, Default, Serialize, Deserialize)]
pub struct State {
    #[serde(default)]
    pub installed: BTreeMap<String, InstalledEntry>,
}

impl State {
    pub fn load(path: &Path) -> Result<Self> {
        match fs::read(path) {
            Ok(bytes) => serde_json::from_slice(&bytes)
                .with_context(|| format!("failed to parse state file {}", path.display())),
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(Self::default()),
            Err(err) => {
                Err(err).with_context(|| format!("failed to read state file {}", path.display()))
            }
        }
    }

    pub fn save(&self, path: &Path) -> Result<()> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("failed to create {}", parent.display()))?;
        }
        let json = serde_json::to_string_pretty(self)?;
        fs::write(path, json)
            .with_context(|| format!("failed to write state file {}", path.display()))
    }
}
