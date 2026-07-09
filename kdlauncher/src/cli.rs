//! Command-line interface definition.

use std::path::PathBuf;

use clap::{Parser, Subcommand};

/// Install and manage kdocker WSL2 distributions from a declarative manifest.
///
/// With no subcommand, kdlauncher reconciles the installed distributions with
/// the versions listed in `kdocker-version.json`.
#[derive(Debug, Parser)]
#[command(name = "kdlauncher", version, about, long_about = None)]
pub struct Cli {
    /// Path to a specific kdocker-version.json manifest to use.
    ///
    /// When omitted, the launcher looks for `kdocker-version.json` next to the
    /// executable, then falls back to `%USERPROFILE%\.kdocker\kdocker-version.json`.
    #[arg(short, long, value_name = "PATH", global = true)]
    pub manifest: Option<PathBuf>,

    /// Assume "yes" for all prompts (non-interactive / unattended runs).
    #[arg(short, long, global = true)]
    pub yes: bool,

    /// Show what would happen without importing or removing anything.
    #[arg(long, global = true)]
    pub dry_run: bool,

    /// Do not pause for a keypress before exiting.
    #[arg(long, global = true)]
    pub no_pause: bool,

    #[command(subcommand)]
    pub command: Option<Command>,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    /// Open an interactive shell into an installed kdocker distribution.
    Shell {
        /// Version to open (defaults to the only installed one, else prompts).
        version: Option<String>,
    },
    /// Show desired (manifest) versus installed distributions.
    List,
    /// Verify WSL2 prerequisites are in place.
    Doctor,
}
