#!/usr/bin/env -S uv run --python python3.11
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "click>=8.1.0",
#     "rich>=13.0.0",
# ]
# ///
"""Update every PyTorch dev env to the latest main and rebuild.

Walks the envs created by setup_pytorch_dev.py (each is a dir holding
`.venv/` and a `pytorch/` source clone). For each one it switches the
clone to `main`, fast-forwards it, updates submodules, and rebuilds.
Binary envs (no `pytorch/` clone) get their nightly torch upgraded.
"""

import os
import subprocess
from pathlib import Path

import click
from rich.console import Console
from rich.table import Table

console = Console()


def git(args, cwd, capture=False, check=True):
    """Run a git command in `cwd`."""
    res = subprocess.run(
        ['git'] + args, cwd=cwd, text=True,
        capture_output=True if capture else False,
        stdout=None, stderr=None,
        check=False,
    )
    if check and res.returncode != 0:
        raise RuntimeError(
            f"git {' '.join(args)} failed in {cwd}"
            + (f":\n{res.stderr}" if capture and res.stderr else "")
        )
    return res.stdout.strip() if capture else res


def is_clean(repo):
    """True if the worktree has no uncommitted (non-submodule) changes."""
    status = git(['status', '--porcelain', '--untracked-files=no'],
                 cwd=repo, capture=True)
    # Ignore submodule pointer churn ("...modified content" / "new commits");
    # those are refreshed by the submodule update step.
    for line in status.splitlines():
        path = line[3:]
        sub = (repo / path)
        if (sub / '.git').exists():
            continue
        return False
    return True


def update_source_env(repo, cuda, dry_run):
    """Switch a source clone to main, fast-forward, rebuild."""
    branch = git(['rev-parse', '--abbrev-ref', 'HEAD'], cwd=repo, capture=True)

    if branch != 'main':
        if not is_clean(repo):
            raise RuntimeError(
                f"on branch '{branch}' with uncommitted changes; "
                "skipping to avoid losing work")
        console.print(f"  switching '{branch}' -> main", style="dim")
        if not dry_run:
            git(['checkout', 'main'], cwd=repo)

    console.print("  fetching + fast-forwarding main", style="dim")
    if not dry_run:
        git(['pull', '--ff-only', 'origin', 'main'], cwd=repo, capture=True)
        git(['submodule', 'update', '--init', '--recursive'], cwd=repo)

    console.print("  cleaning previous build...", style="dim")
    console.print(
        f"  building ({'cuda' if cuda else 'cpu'})...", style="dim")
    if dry_run:
        return

    venv = repo.parent / '.venv'
    build = "USE_CUDA=1 " if cuda else ""
    # Clean then build through an interactive bash so the BUILD_CONFIG alias
    # resolves. ccache keeps the rebuild fast despite the clean.
    cmd = (f"source {venv}/bin/activate && "
           f"uv pip install -r requirements-build.txt && "
           f"spin clean && "
           f"BUILD_CONFIG {build}spin develop")
    res = subprocess.run(['bash', '-ic', cmd], cwd=repo)
    if res.returncode != 0:
        raise RuntimeError("build failed")


def update_reference(reference, dry_run):
    """Refresh the shared reference clone the envs are cloned against."""
    console.print("  pulling + updating submodules", style="dim")
    if dry_run:
        return
    git(['pull'], cwd=reference, capture=True)
    git(['submodule', 'update', '--init', '--recursive'], cwd=reference)


def update_binary_env(env, cuda, dry_run):
    """Upgrade the nightly torch wheel in a binary env."""
    chan = cuda if cuda else 'cpu'
    index = f'https://download.pytorch.org/whl/nightly/{chan}'
    console.print(f"  upgrading nightly torch ({chan})", style="dim")
    if dry_run:
        return
    venv = str(env / '.venv')
    subprocess.run(
        ['uv', 'pip', 'install', '--pre', '--upgrade', 'torch', '-f', index],
        env={**os.environ, 'VIRTUAL_ENV': venv}, check=True)


@click.command()
@click.option('--base', default=str(Path.home() / 'local' / 'pytorch'),
              help='Base directory holding the envs')
@click.option('--dry-run', is_flag=True, help='Show what would be done')
def main(base, dry_run):
    """Update all PyTorch dev envs to latest main and rebuild."""
    base = Path(base)
    if not base.is_dir():
        raise click.ClickException(f"Base dir not found: {base}")

    envs = [d for d in base.iterdir()
            if d.is_dir() and (d / '.venv').is_dir()]
    if not envs:
        raise click.ClickException(f"No envs (dirs with .venv) under {base}")

    # cuda envs first, then the rest; both groups sorted by name for a
    # consistent, reproducible order across runs.
    envs.sort(key=lambda d: (0 if 'cuda' in d.name.lower() else 1, d.name))

    console.print(f"\n[bold cyan]Updating {len(envs)} env(s) in {base}"
                  f"[/bold cyan]\n")

    # Refresh the shared reference clone first so every env clones/pulls
    # against up-to-date objects.
    reference = base / 'reference'
    if (reference / '.git').exists():
        console.rule("[magenta]reference[/magenta]")
        try:
            update_reference(reference, dry_run)
            console.print("  ✓ done", style="green")
        except Exception as e:
            console.print(f"  [red]✗ {e}[/red]")
            raise click.ClickException(f"reference update failed: {e}")

    results = []
    for env in envs:
        cuda = 'cuda' in env.name.lower()
        repo = env / 'pytorch'
        console.rule(f"[cyan]{env.name}[/cyan]")
        try:
            if (repo / '.git').exists():
                update_source_env(repo, cuda, dry_run)
            else:
                update_binary_env(env, cuda, dry_run)
            results.append((env.name, "ok"))
            console.print("  ✓ done", style="green")
        except Exception as e:
            results.append((env.name, f"FAILED: {e}"))
            console.print(f"  [red]✗ {e}[/red]")

    table = Table(title="Update Summary", show_header=True)
    table.add_column("Env", style="cyan")
    table.add_column("Result")
    for name, status in results:
        style = "green" if status == "ok" else "red"
        table.add_row(name, f"[{style}]{status}[/{style}]")
    console.print()
    console.print(table)

    if any(s != "ok" for _, s in results):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
