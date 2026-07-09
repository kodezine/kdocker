//! `shell` subcommand: open an interactive shell into a kdocker distribution.

use anyhow::{bail, Result};

use crate::naming::{distro_name, version_from_distro};
use crate::{ui, wsl};

pub fn run(version: Option<&str>) -> Result<()> {
    if !wsl::is_available() {
        bail!("WSL is not available. Run `kdlauncher doctor` for details.");
    }

    let installed = wsl::list_kdocker_distros()?;
    if installed.is_empty() {
        bail!("No kdocker distributions are installed. Run kdlauncher to install one.");
    }

    let distro = match version {
        Some(v) => {
            let name = distro_name(v);
            if !installed.contains(&name) {
                bail!("{name} is not installed.");
            }
            name
        }
        None if installed.len() == 1 => installed[0].clone(),
        None => {
            let versions: Vec<String> = installed
                .iter()
                .filter_map(|d| version_from_distro(d))
                .collect();
            match ui::choose("Multiple kdocker versions are installed:", &versions) {
                Some(i) => distro_name(&versions[i]),
                None => {
                    bail!("No version selected. Pass a version, e.g. `kdlauncher shell 1.2.3`.")
                }
            }
        }
    };

    println!("Launching {distro} ...");
    wsl::shell(&distro)
}
