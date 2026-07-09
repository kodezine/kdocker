//! Thin wrapper around the Windows `wsl.exe` command-line tool.

use std::path::Path;
use std::process::{Command, Stdio};

use anyhow::{anyhow, bail, Context, Result};

use crate::naming::DISTRO_PREFIX;

const WSL: &str = "wsl.exe";

/// Whether `wsl.exe` is available on PATH.
///
/// This only checks whether the process can be spawned, not its exit code:
/// some WSL builds return non-zero for `--version` yet are fully usable.
pub fn is_available() -> bool {
    Command::new(WSL)
        .arg("--version")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok()
}

/// Raw `wsl.exe --status` output (decoded from UTF-16).
pub fn status() -> Result<String> {
    let output = Command::new(WSL)
        .arg("--status")
        .output()
        .context("failed to run `wsl.exe --status`")?;
    if !output.status.success() {
        let mut detail = decode(&output.stderr);
        if detail.trim().is_empty() {
            detail = decode(&output.stdout);
        }
        bail!("`wsl.exe --status` failed: {}", detail.trim());
    }
    Ok(decode(&output.stdout))
}

/// Set the default WSL version (typically 2).
pub fn set_default_version(version: u8) -> Result<()> {
    run_checked(&["--set-default-version", &version.to_string()])
}

/// List installed distribution names.
pub fn list_distros() -> Result<Vec<String>> {
    let output = Command::new(WSL)
        .args(["--list", "--quiet"])
        .output()
        .context("failed to run `wsl.exe --list --quiet`")?;
    if !output.status.success() {
        bail!("`wsl.exe --list` failed: {}", decode(&output.stderr).trim());
    }
    Ok(parse_distro_list(&decode(&output.stdout)))
}

/// List installed kdocker distributions only.
pub fn list_kdocker_distros() -> Result<Vec<String>> {
    Ok(list_distros()?
        .into_iter()
        .filter(|d| d.starts_with(DISTRO_PREFIX))
        .collect())
}

/// Import a rootfs tarball as a new WSL2 distribution.
pub fn import(name: &str, install_dir: &Path, tarball: &Path) -> Result<()> {
    let dir = install_dir
        .to_str()
        .ok_or_else(|| anyhow!("install dir is not valid UTF-8"))?;
    let tar = tarball
        .to_str()
        .ok_or_else(|| anyhow!("tarball path is not valid UTF-8"))?;
    run_checked(&["--import", name, dir, tar, "--version", "2"])
}

/// Unregister (delete) a distribution. This is destructive.
pub fn unregister(name: &str) -> Result<()> {
    run_checked(&["--unregister", name])
}

/// Launch an interactive shell into a distribution, inheriting stdio.
pub fn shell(name: &str) -> Result<()> {
    let status = Command::new(WSL)
        .args(["-d", name])
        .status()
        .with_context(|| format!("failed to launch shell into {name}"))?;
    if !status.success() {
        bail!("shell session for {name} exited with a non-zero status");
    }
    Ok(())
}

fn run_checked(args: &[&str]) -> Result<()> {
    let output = Command::new(WSL)
        .args(args)
        .output()
        .with_context(|| format!("failed to run `wsl.exe {}`", args.join(" ")))?;
    if !output.status.success() {
        bail!(
            "`wsl.exe {}` failed: {}",
            args.join(" "),
            decode(&output.stderr).trim()
        );
    }
    Ok(())
}

/// Decode `wsl.exe` output, which is UTF-16LE on Windows.
fn decode(bytes: &[u8]) -> String {
    let looks_utf16 = bytes.len() >= 2
        && bytes.len().is_multiple_of(2)
        && bytes.chunks_exact(2).take(16).filter(|c| c[1] == 0).count()
            > bytes.chunks_exact(2).take(16).count() / 2;

    if looks_utf16 {
        let units: Vec<u16> = bytes
            .chunks_exact(2)
            .map(|c| u16::from_le_bytes([c[0], c[1]]))
            .collect();
        String::from_utf16_lossy(&units)
    } else {
        String::from_utf8_lossy(bytes).into_owned()
    }
}

fn parse_distro_list(text: &str) -> Vec<String> {
    text.lines()
        .map(|l| l.trim().trim_matches('\u{0}').trim())
        .filter(|l| !l.is_empty())
        .map(str::to_owned)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decode_handles_utf16le() {
        // "Ubuntu" in UTF-16LE.
        let bytes: Vec<u8> = "Ubuntu"
            .encode_utf16()
            .flat_map(|u| u.to_le_bytes())
            .collect();
        assert_eq!(decode(&bytes).trim_end_matches('\u{0}'), "Ubuntu");
    }

    #[test]
    fn decode_handles_utf8() {
        assert_eq!(decode(b"Ubuntu\n").trim(), "Ubuntu");
    }

    #[test]
    fn parse_list_splits_and_trims() {
        let got = parse_distro_list("kdocker-wsl-v1.0.0\nUbuntu\n\n");
        assert_eq!(got, vec!["kdocker-wsl-v1.0.0", "Ubuntu"]);
    }
}
