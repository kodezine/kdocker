//! `list` subcommand: show desired (manifest) versus installed distributions.

use std::collections::BTreeSet;

use anyhow::Result;

use crate::cli::Cli;
use crate::config::Paths;
use crate::manifest::{self, Resolved};
use crate::naming::version_from_distro;
use crate::wsl;

pub fn run(cli: &Cli) -> Result<()> {
    let paths = Paths::resolve()?;

    let desired: BTreeSet<String> = match manifest::resolve(cli.manifest.as_deref(), &paths)? {
        Resolved::Found(path, manifest) => {
            println!("Manifest: {}", path.display());
            manifest.unique_versions().into_iter().collect()
        }
        Resolved::Missing(path) => {
            println!(
                "Manifest: (none yet, would be created at {})",
                path.display()
            );
            BTreeSet::new()
        }
    };

    let installed: BTreeSet<String> = if wsl::is_available() {
        wsl::list_kdocker_distros()?
            .iter()
            .filter_map(|d| version_from_distro(d))
            .collect()
    } else {
        println!("(WSL not available; cannot list installed distributions)");
        BTreeSet::new()
    };

    let all: BTreeSet<&String> = desired.union(&installed).collect();
    if all.is_empty() {
        println!("\nNo kdocker versions desired or installed.");
        return Ok(());
    }

    println!("\n{:<16} {:<10} INSTALLED", "VERSION", "DESIRED");
    for version in all {
        println!(
            "{:<16} {:<10} {}",
            version,
            yes_no(desired.contains(version)),
            yes_no(installed.contains(version)),
        );
    }
    Ok(())
}

fn yes_no(b: bool) -> &'static str {
    if b {
        "yes"
    } else {
        "-"
    }
}
