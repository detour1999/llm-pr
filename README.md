# PR Helper

PR Helper is an automated tool designed to simplify the process of creating pull requests for developers. It harnesses the power of language models via the `llm` command-line tool to analyze the changes (diff) introduced in a Git branch and intelligently generate a concise and informative title and body for the pull request. This eliminates the need for manual summarization of the changes by the developer, ensuring a consistent and informative pull request structure and ultimately saving time and effort.

## Prerequisites

Before you begin, ensure you have the following installed:

### [GitHub CLI (gh)](https://cli.github.com/)
  #### On macOS
  You can install `gh` using [Homebrew](https://brew.sh/):
  ```bash
  brew install gh
  ```

  #### Debian/Ubuntu
  ```bash
  sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y
  ```

  For more detailed information and additional installation methods, visit the official [GitHub CLI installation guide](https://github.com/cli/cli#installation).

  #### Configuration
  Run `gh auth login` to authenticate with your GitHub account. Alternatively, gh will respect the `GITHUB_TOKEN` environment variable.


### [llm](https://llm.datasette.io/en/stable/)
  #### Install
    ```pip install llm```
    or
    ```brew install llm```
    or
    ```pipx install llm```

  #### After installation:
    ```
    # Paste your OpenAI API key into this
    llm keys set openai
    ```

## Functionality

The script performs the following operations:

1. Fetches the repository information such as the default branch and the name with owner using the `gh repo view` command.
2. Retrieves the list of git remotes and their associated URLs with `git remote -v`.
3. Isolates the GitHub remotes from the list of remotes and fetches the GitHub URL.
4. Extracts the repository owner and name from the `gh` JSON output using `jq`.
5. Determines the current branch name.
6. Generates the title and body for the PR based on diffs between the current and base branches, using the `llm` tool invoked with prompts configured in your `~/.config/prompts/`.
7. Outputs the command to create a pull request with the generated title and body.

## Usage

To use the script, you may need to make it executable with `chmod +x` and then you can run it directly from your terminal:

```bash
./pr.sh
```

To ensure the `pr-helper` tool is easily accessible from any location on your system, you may create a symbolic link (`symlink`) to the `pr.sh` script in a directory that's included in your `PATH`. This can be done by running the following command in your terminal:

```bash
ln -s /path/to/pr-helper/pr.sh /usr/local/bin/pr-helper
```
Note that if you want to make your script available system-wide (for all users), you'll need to move or link it to a system directory like `/usr/local/bin` (as shown above). If you only want it available for your user account, you can use `~/bin` instead.

With this symlink in place, you can run `pr-helper` from any directory without needing to specify the full path to the script.

Ensure that your `~/.config/prompts/` directory contains the required `pr-title-prompt.txt` and `pr-body-prompt.txt` files for the `llm` tool to work correctly.

These are intentionally kept separate from this repo so that they can be iterated on and not overwritten by a git pull.

Below are comments and example text for each `.txt` file that the `llm` tool will use to generate the title and body for a pull request:

### `pr-title-prompt.txt`

Comment: This file should contain the prompt for generating the PR title based on the code changes. Ideally, it should instruct the AI to summarize the main purpose or feature added.

Example:
```
Write concise, informative pull request title:

* It should be a very short summary in imperative mood
* Explain the 'why' behind changes more so than the changes
* Keep the title under 50 characters
* If there are no changes, or the input is blank - then return a blank string

Think carefully before you write your title.

What you write will be passed to create the title of a github pull request
```

### `pr-body-prompt.txt`

Comment: This file should contain the prompt for generating the PR body. It should guide the AI to detail out the changes made, any dependencies added or removed, and if necessary, link to any relevant issues.

Example:
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

## Issues
If you have any feedback or encounter any issues, please submit an issue on the repository's issue tracker, or drop me a line [hi@dylanr.com](mailto:hi@dylanr.com).

## License

This script is released under the MIT License - see the [LICENSE](LICENSE) file for details.

## Next

Adding support for pierre?
