//! kdlauncher — install and manage kdocker WSL2 distributions from a manifest.
//!
//! Running the launcher with no subcommand reconciles the installed WSL
//! distributions against the versions listed in `kdocker-version.json`.

mod cli;
mod commands;
mod config;
mod manifest;
mod naming;
mod reconcile;
mod registry;
mod ui;
mod wsl;

use std::process::ExitCode;

use clap::Parser;

use crate::cli::{Cli, Command};

fn main() -> ExitCode {
    let cli = Cli::parse();
    let interactive = !cli.yes && std::io::IsTerminal::is_terminal(&std::io::stdin());

    let result = run(&cli);

    let code = match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(err) => {
            eprintln!("\n{} {err:#}", ui::error_tag());
            ExitCode::FAILURE
        }
    };

    // Pause so a double-clicked window does not vanish before output is read.
    if interactive && !cli.no_pause {
        ui::pause();
    }

    code
}

fn run(cli: &Cli) -> anyhow::Result<()> {
    match &cli.command {
        None => reconcile::run(cli),
        Some(Command::Shell { version }) => commands::shell::run(version.as_deref()),
        Some(Command::List) => commands::list::run(cli),
        Some(Command::Doctor) => commands::doctor::run(),
    }
}
