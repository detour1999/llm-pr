# LLM PR Helper
LLM PR Helper is an automated tool designed to simplify the process of creating pull requests for developers. It uses language models via the `llm` command-line tool to analyze the changes introduced in a Git branch and generates a concise and informative title and body for the pull request.

## Table of Contents
1. [Prerequisites](#prerequisites)
   - [llm](#llm)
   - [GitHub CLI (gh)](#github-cli-gh)
2. [Features](#features)
3. [Usage](#usage)
4. [Customization](#customization)
5. [Issues and Feedback](#issues-and-feedback)
6. [License](#license)

## Prerequisites

The script will check for required dependencies and provide installation instructions if anything is missing.

Required:
- **git**: Version control system
- **jq**: Command-line JSON processor
- **llm**: CLI tool for language models

Optional:
- **GitHub CLI (gh)**: For creating PRs directly from the command line

### Installation Instructions

#### llm
```bash
pip install llm
# or
brew install llm
# or
pipx install llm

# After installing:
llm keys set openai
# Follow the prompts to input your OpenAI API key
```

#### GitHub CLI (gh) _optional_
_If not installed, the script will still generate and output a PR title and body._

```bash
# macOS
brew install gh

# Debian/Ubuntu
sudo apt install gh

# After installing:
gh auth login
```


## Features

- Automatically generates PR titles and descriptions based on your code changes
- Smart detection of the correct base branch
- Option to create draft PRs by adding the [DRAFT] prefix
- Handles pushing unpushed commits and creating remote branches when needed
- Supports updating existing PRs
- Works with GitHub repositories
- Configurable prompt location through environment variables
- Helpful dependency checks with clear installation instructions
- Guided first-time setup experience

## Usage

1. Run the script and follow the interactive setup:
   - Choose where to store your prompt templates
   - Optionally save this location in your shell configuration
   - Edit the default prompts directly during setup, or use the defaults
   - You can always edit the prompt files later (see [Customization](#customization))

2. Make the script executable:
   ```bash
   chmod +x pr.sh
   ```

3. Run directly from your terminal:
   ```bash
   ./pr.sh
   ```

For easier access, either:
- Add the script directory to your `PATH`
- Create a symlink in a directory already in your `PATH`:
  ```bash
  ln -s $(pwd)/pr.sh /usr/local/bin/pr
  ```

For the smoothest workflow, create a git alias:
```bash
git config --global alias.pr '!pr.sh'
```

Then your PR workflow becomes:
```bash
git commit -a
git push
git pr
```

## Customization

The script uses separate prompt files for PR titles and bodies. The interactive setup process:

1. Asks where you want to store your prompts (suggesting `~/.config/prompts/` as default)
2. Offers to save this preference to your shell config (`.zshrc`, `.bashrc`, or `.profile`)
3. Shows default templates that you can:
   - Use as-is (press Enter)
   - Edit directly during setup (using your $EDITOR if set, or direct input)
   - Customize later by editing the files

You can always:
- Edit the prompt files directly to customize them
- Change the location by setting the `PROMPT_DIR` environment variable:

```bash
# Example: Use prompts in the current repository
export PROMPT_DIR="$(pwd)/prompts"
./pr.sh
```

### `pr-title-prompt.txt`
```
Write a concise, informative pull request title:

* It should be a very short summary in imperative mood
* Explain the 'why' behind changes more so than the changes
* Keep the title under 50 characters
* If there are no changes, or the input is blank - then return a blank string

Think carefully before you write your title.

What you write will be passed to create the title of a github pull request
```

### `pr-body-prompt.txt`
```
Write a clear, informative pull request message in markdown:

* Remember to mention the files that were changed, and what was changed
* Start with a summary
* Explain the 'why' behind changes
* Include a bulleted list to outline all of the changes
* If there are changes that resolve specified issues add the issues to a list of closed issues
* If there are no changes, or the input is blank - then return a blank string

Think carefully before you write your pull request body.

What you write will be passed to create a github pull request
```

## Issues and Feedback

For issues, feature requests, or feedback:
- Open an issue in the GitHub repository
- Contact the maintainer at [hi@dylanr.com](mailto:hi@dylanr.com)

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.
