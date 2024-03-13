# PR Helper
PR Helper is an automated tool designed to simplify the process of creating pull requests for developers. It uses language models via the `llm` command-line tool to analyze the changes introduced in a Git branch and generates a concise and informative title and body for the pull request.

## Table of Contents
1. [Prerequisites](#prerequisites)
   - [GitHub CLI (gh)](#github-cli-gh)
   - [llm](#llm)
2. [Functionality](#functionality)
3. [Usage](#usage)
4. [Customization](#customization)
5. [Issues and Feedback](#issues-and-feedback)
6. [License](#license)

## Prerequisites

### llm
Install by running one of the commands below:
```bash
pip install llm
brew install llm
pipx install llm
```
After installing:
```bash
llm keys set openai
# Follow the prompts to input your OpenAI API key
```

### GitHub CLI (gh) _optional_
_If not installed, the script won't actually create a Pull Request, but will generate and output a title and body._

Installed using preferred method as per the official [guide](https://github.com/cli/cli#installation).

#### macOS
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

#### Configuration
Authenticate using `gh auth login`. The `GITHUB_TOKEN` environment variable is also supported.



## Usage

Set up `~/.config/prompts/` with `pr-title-prompt.txt` and `pr-body-prompt.txt`.

To use the script, you may need to make it executable with `chmod +x` and then you can run it directly from your terminal:
```bash
./pr.sh
```
To ensure the `pr-helper` tool is easily accessible from any location on your system, you may create a symbolic link (`symlink`) to the `pr.sh` script in a directory that's included in your `PATH`. Alternatively, add the directory with the script to your `PATH`.

## Customization

The `llm` tool uses separate `.txt` files for PR titles and bodies, so they can be adapted to your needs.

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

Report issues or provide feedback at [hi@dylanr.com](mailto:hi@dylanr.com) or via the issue tracker.

## License

Released under the MIT License, see [LICENSE](LICENSE).
