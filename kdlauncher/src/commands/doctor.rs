//! `doctor` subcommand: verify WSL2 prerequisites.

use anyhow::Result;

use crate::wsl;

pub fn run() -> Result<()> {
    println!("Checking WSL prerequisites...\n");

    if !wsl::is_available() {
        println!("✗ wsl.exe not found on PATH.");
        println!("  Fix: open an elevated PowerShell and run `wsl --install`, then reboot.");
        return Ok(());
    }
    println!("✓ wsl.exe is available");

    match wsl::status() {
        Ok(status) => {
            let status = status.trim();
            if status.is_empty() {
                println!("! `wsl --status` returned no output");
            } else {
                println!("\n--- wsl --status ---");
                for line in status.lines() {
                    println!("  {}", line.trim_end());
                }
                println!("--------------------");
            }

            if status.contains("Default Version: 1") {
                println!(
                    "\n! Default WSL version is 1. kdocker needs WSL2.\n  Fix: run `wsl --set-default-version 2`."
                );
            }
        }
        Err(err) => println!("! could not read `wsl --status`: {err:#}"),
    }

    match wsl::list_kdocker_distros() {
        Ok(distros) if distros.is_empty() => {
            println!("\nNo kdocker distributions installed yet.");
        }
        Ok(distros) => {
            println!("\nInstalled kdocker distributions:");
            for d in distros {
                println!("  - {d}");
            }
        }
        Err(err) => println!("\n! could not list distributions: {err:#}"),
    }

    Ok(())
}
