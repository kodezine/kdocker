//! Small interactive helpers: prompts and end-of-run pause.

use std::io::{self, IsTerminal, Write};

/// Coloured `error:` tag for the top-level error handler. Renders in red when
/// stderr is a terminal, and falls back to a plain prefix otherwise.
pub fn error_tag() -> &'static str {
    if io::stderr().is_terminal() {
        "\x1b[31merror:\x1b[0m"
    } else {
        "error:"
    }
}

/// Ask a yes/no question. Returns `assume_yes` immediately when set, and `false`
/// when there is no interactive terminal to answer the prompt.
pub fn confirm(question: &str, assume_yes: bool) -> bool {
    if assume_yes {
        return true;
    }
    if !io::stdin().is_terminal() {
        return false;
    }

    loop {
        print!("{question} [y/N]: ");
        if io::stdout().flush().is_err() {
            return false;
        }
        let mut line = String::new();
        if io::stdin().read_line(&mut line).is_err() {
            return false;
        }
        match line.trim().to_ascii_lowercase().as_str() {
            "y" | "yes" => return true,
            "" | "n" | "no" => return false,
            _ => println!("Please answer 'y' or 'n'."),
        }
    }
}

/// Prompt the user to choose one item from a list. Returns the chosen index.
pub fn choose(prompt: &str, items: &[String]) -> Option<usize> {
    if !io::stdin().is_terminal() {
        return None;
    }
    println!("{prompt}");
    for (i, item) in items.iter().enumerate() {
        println!("  {}) {item}", i + 1);
    }
    loop {
        print!("Select [1-{}]: ", items.len());
        io::stdout().flush().ok()?;
        let mut line = String::new();
        io::stdin().read_line(&mut line).ok()?;
        match line.trim().parse::<usize>() {
            Ok(n) if n >= 1 && n <= items.len() => return Some(n - 1),
            _ => println!("Invalid selection."),
        }
    }
}

/// Wait for the user to press Enter before returning.
pub fn pause() {
    print!("\nPress Enter to exit...");
    let _ = io::stdout().flush();
    let mut buf = String::new();
    let _ = io::stdin().read_line(&mut buf);
}
