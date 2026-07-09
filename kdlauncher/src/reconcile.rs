//! Reconcile installed WSL distributions with the manifest's desired state.

use std::collections::BTreeSet;

use anyhow::{Context, Result};

use crate::cli::Cli;
use crate::config::{InstalledEntry, Paths, State};
use crate::manifest::{self, Manifest, Resolved};
use crate::naming::{self, distro_name, version_from_distro};
use crate::registry::Registry;
use crate::{ui, wsl};

pub fn run(cli: &Cli) -> Result<()> {
    let paths = Paths::resolve()?;

    preflight(cli.dry_run)?;

    // Lazily connect to the registry; needed for install and latest resolution.
    let mut registry: Option<Registry> = None;

    let (manifest_path, manifest) = load_or_create(cli, &paths, &mut registry)?;
    println!("Using manifest: {}", manifest_path.display());

    let desired: BTreeSet<String> = manifest.unique_versions().into_iter().collect();
    if desired.is_empty() {
        println!("Manifest lists no versions; nothing to install.");
    }

    let installed =
        wsl::list_kdocker_distros().context("failed to list installed distributions")?;
    let actual: BTreeSet<String> = installed
        .iter()
        .filter_map(|d| version_from_distro(d))
        .collect();

    let mut state = State::load(&paths.state_file)?;

    // 1. Install versions that are desired but not present.
    for version in desired.difference(&actual) {
        install_version(cli, &paths, &mut registry, &mut state, version)?;
    }

    // 2. Notify about versions already installed.
    for version in desired.intersection(&actual) {
        println!("✓ {} already installed", distro_name(version));
    }

    // 3. Offer to remove distributions dropped from the manifest.
    for version in actual.difference(&desired) {
        remove_version(cli, &paths, &mut state, version)?;
    }

    if !cli.dry_run {
        state.save(&paths.state_file)?;
    }

    println!("\nReconcile complete.");
    Ok(())
}

fn load_or_create(
    cli: &Cli,
    paths: &Paths,
    registry: &mut Option<Registry>,
) -> Result<(std::path::PathBuf, Manifest)> {
    match manifest::resolve(cli.manifest.as_deref(), paths)? {
        Resolved::Found(path, manifest) => Ok((path, manifest)),
        Resolved::Missing(path) => {
            println!(
                "No manifest found. A new one will be created at:\n  {}",
                path.display()
            );
            let reg = ensure_registry(registry)?;
            let latest = reg
                .latest_version()
                .context("failed to determine the latest kdocker version")?;
            println!("Latest available version: {latest}");

            let manifest = Manifest {
                versions: vec![latest.clone()],
            };
            if cli.dry_run {
                println!("[dry-run] would write manifest with version {latest}");
            } else {
                manifest.save(&path)?;
                println!("Created manifest with version {latest}.");
            }
            Ok((path, manifest))
        }
    }
}

fn install_version(
    cli: &Cli,
    paths: &Paths,
    registry: &mut Option<Registry>,
    state: &mut State,
    version: &str,
) -> Result<()> {
    let distro = distro_name(version);
    println!("\nInstalling {distro} ...");

    if cli.dry_run {
        println!("[dry-run] would download rootfs for {version} and import as {distro}");
        return Ok(());
    }

    let reg = ensure_registry(registry)?;

    let install_dir = paths.install_dir(version);
    std::fs::create_dir_all(&install_dir)
        .with_context(|| format!("failed to create {}", install_dir.display()))?;

    // Download to a temporary file inside the install dir, then import.
    let tarball = install_dir.join("rootfs.tar.gz");
    let digest = reg
        .download_rootfs(version, &tarball)
        .with_context(|| format!("failed to download rootfs for {version}"))?;

    wsl::import(&distro, &install_dir, &tarball)
        .with_context(|| format!("failed to import {distro}"))?;

    // The imported distribution keeps its own copy; drop the tarball.
    let _ = std::fs::remove_file(&tarball);

    state.installed.insert(
        version.to_string(),
        InstalledEntry {
            distro: distro.clone(),
            install_dir,
            digest,
        },
    );

    println!("✓ Installed {distro}");
    Ok(())
}

fn remove_version(cli: &Cli, paths: &Paths, state: &mut State, version: &str) -> Result<()> {
    let distro = distro_name(version);
    println!(
        "\n{} was removed from the manifest but is still registered in WSL.",
        distro
    );

    let question = format!("Unregister {distro} and delete its data?");
    if !ui::confirm(&question, cli.yes) {
        println!("Keeping {distro}.");
        return Ok(());
    }

    if cli.dry_run {
        println!("[dry-run] would unregister {distro}");
        return Ok(());
    }

    wsl::unregister(&distro).with_context(|| format!("failed to unregister {distro}"))?;

    // Clean up the install directory and state entry.
    let install_dir = state
        .installed
        .remove(version)
        .map(|e| e.install_dir)
        .unwrap_or_else(|| paths.install_dir(version));
    let _ = std::fs::remove_dir_all(&install_dir);

    println!("✓ Removed {distro}");
    Ok(())
}

fn ensure_registry(registry: &mut Option<Registry>) -> Result<&Registry> {
    if registry.is_none() {
        *registry = Some(Registry::connect().context("failed to connect to the registry")?);
    }
    Ok(registry.as_ref().expect("registry just initialized"))
}

/// Verify WSL prerequisites before doing any work.
fn preflight(dry_run: bool) -> Result<()> {
    if !wsl::is_available() {
        anyhow::bail!(
            "WSL was not found. Install it with `wsl --install` and reboot, then try again."
        );
    }
    // Best-effort: make WSL2 the default for new imports.
    if !dry_run {
        let _ = wsl::set_default_version(2);
    }
    let _ = naming::REGISTRY; // silence unused in some cfgs
    Ok(())
}
