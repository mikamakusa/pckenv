# pckenv

[Packer](https://www.packer.io/) version manager inspired by [pckenv](https://github.com/tfutils/pckenv)

## Supports
Currently, pckenv has been tested only on **Linux 64bits**

## Installation
### Manual
1. Check out pckenv into any path (here is `${HOME}/.pckenv`)

```console
$ git clone --depth=1 https://github.com/mikamakusa/pckenv.git ~/.pckenv
```

2. Add `~/.pckenv/bin` to your `$PATH` any way you like

```console
$ echo 'export PATH="$HOME/.pckenv/bin:$PATH"' >> ~/.bash_profile
```

For WSL users
```bash
$ echo 'export PATH=$PATH:$HOME/.pckenv/bin' >> ~/.bashrc
```

OR you can make symlinks for `pckenv/bin/*` scripts into a path that is already added to your `$PATH` (e.g. `/usr/local/bin`) `OSX/Linux Only!`

```console
$ ln -s ~/.pckenv/bin/* /usr/local/bin
```

On Ubuntu/Debian touching `/usr/local/bin` might require sudo access, but you can create `${HOME}/bin` or `${HOME}/.local/bin` and on next login it will get added to the session `$PATH`
or by running `. ${HOME}/.profile` it will get added to the current shell session's `$PATH`.

```console
$ mkdir -p ~/.local/bin/
$ . ~/.profile
$ ln -s ~/.pckenv/bin/* ~/.local/bin
$ which pckenv
```

## Usage

### pckenv install [version]

Install a specific version of Terraform.

If no parameter is passed, the version to use is resolved automatically via [pckenv\_TERRAFORM\_VERSION environment variable](#pckenv_packer_version) or [.packer-version files](#packer-version-file), in that order of precedence, i.e. pckenv\_TERRAFORM\_VERSION, then .packer-version. The default is 'latest' if none are found.

If a parameter is passed, available options:

- `x.y.z` [Semver 2.0.0](https://semver.org/) string specifying the exact version to install
- `latest` is a syntax to install latest version
- `latest:<regex>` is a syntax to install latest version matching regex (used by grep -e)
- `latest-allowed` is a syntax to scan your Terraform files to detect which version is maximally allowed.
- `min-required` is a syntax to scan your Terraform files to detect which version is minimally required.

See [required_version](https://developer.hashicorp.com/packer/docs/templates/hcl_templates/blocks/packer) docs. Also [see min-required & latest-allowed](#min-required) section below.

```console
$ pckenv install
$ pckenv install 0.7.0
$ pckenv install latest
$ pckenv install latest:^0.8
$ pckenv install latest-allowed
$ pckenv install min-required
```

If `shasum` is present in the path, pckenv will verify the download against Hashicorp's published sha256 hash.
If [keybase](https://keybase.io/) is available in the path it will also verify the signature for those published hashes using Hashicorp's published public key.

You can opt-in to using GnuPG tools for PGP signature verification if keybase is not available:

Where `PCKENV_INSTALL_DIR` is for example, `~/.pckenv` or `/usr/local/pckenv/<version>`

```console
$ echo 'trust-pckenv: yes' > ${PCKENV_INSTALL_DIR}/use-gpgv
$ pckenv install
```

The `trust-pckenv` directive means that verification uses a copy of the
Hashicorp OpenPGP key found in the pckenv repository.  Skipping that directive
means that the Hashicorp key must be in the existing default trusted keys.
Use the file `${PCKENV_INSTALL_DIR}/use-gnupg` to instead invoke the full `gpg` tool and
see web-of-trust status; beware that a lack of trust path will not cause a
validation failure.

#### .packer-version

If you use a [.packer-version](#packer-version-file) file, `pckenv install` (no argument) will install the version written in it.

<a name="min-required"></a>
#### min-required & latest-allowed

Please note that we don't do semantic version range parsing but use first ever found version as the candidate for minimally required one. It is up to the user to keep the definition reasonable. I.e.

```packer
// this will detect 1.8.6
packer {
  required_version  = "<1.8.7, >= 1.8.5"
}
```
### Environment Variables

#### PCKENV

##### `PCKENV_ARCH`

String (Default: `amd64`)

Specify architecture. Architecture other than the default amd64 can be specified with the `PCKENV_ARCH` environment variable

Note: Default changes to `arm64` for versions that have arm64 builds available when `$(uname -m)` matches `aarch64* | arm64*`

```console
$ PCKENV_ARCH=arm64 pckenv install 0.7.9
```

##### `PCKENV_AUTO_INSTALL`

String (Default: true)

Should pckenv automatically install packer if the version specified by defaults or a .packer-version file is not currently installed.

```console
$ PCKENV_AUTO_INSTALL=false packer init
```

```console
$ packer use <version that is not yet installed>
```

##### `PCKENV_CURL_OUTPUT`

Integer (Default: 2)

Set the mechanism used for displaying download progress when downloading packer versions from the remote server.

* 2: v1 Behaviour: Pass `-#` to curl
* 1: Use curl default
* 0: Pass `-s` to curl

##### `PCKENV_DEBUG`

Integer (Default: 0)

Set the debug level for PCKENV.

* 0: No debug output
* 1: Simple debug output
* 2: Extended debug output, with source file names and interactive debug shells on error
* 3: Debug level 2 + Bash execution tracing

##### `PCKENV_REMOTE`

String (Default: https://releases.hashicorp.com)

To install from a remote other than the default

```console
$ PCKENV_REMOTE=https://example.jfrog.io/artifactory/hashicorp
```

##### `PCKENV_REVERSE_REMOTE`

Integer (Default: 0)

When using a custom remote, such as Artifactory, instead of the Hashicorp servers,
the list of packer versions returned by the curl of the remote directory may be inverted.
In this case the `latest` functionality will not work as expected because it expects the
versions to be listed in order of release date from newest to oldest. If your remote
is instead providing a list that is oldes-first, set `PCKENV_REVERSE_REMOTE=1` and
functionality will be restored.

```console
$ PCKENV_REVERSE_REMOTE=1 pckenv list-remote
```

##### `PCKENV_CONFIG_DIR`

Path (Default: `$PCKENV_ROOT`)

The path to a directory where the local packer versions and configuration files exist.

```console
PCKENV_CONFIG_DIR="$XDG_CONFIG_HOME/pckenv"
```

##### `PCKEND_PACKER_VERSION`

String (Default: "")

If not empty string, this variable overrides Terraform version, specified in [.packer-version files](#packer-version-file).
`latest` and `latest:<regex>` syntax are also supported.
[`pckenv install`](#pckenv-install-version) and [`pckenv use`](#pckenv-use-version) command also respects this variable.

e.g.

```console
$ PCKEND_PACKER_VERSION=latest:^0.11. packer --version
```

##### `PCKENV_NETRC_PATH`

String (Default: "")

If not empty string, this variable specifies the credentials file used to access the remote location (useful if used in conjunction with PCKENV_REMOTE).

e.g.

```console
$ PCKENV_NETRC_PATH="$PWD/.netrc.pckenv"
```

#### Bashlog Logging Library

##### `BASHLOG_COLOURS`

Integer (Default: 1)

To disable colouring of console output, set to 0.


##### `BASHLOG_DATE_FORMAT`

String (Default: +%F %T)

The display format for the date as passed to the `date` binary to generate a datestamp used as a prefix to:

* `FILE` type log file lines.
* Each console output line when `BASHLOG_EXTRA=1`

##### `BASHLOG_EXTRA`

Integer (Default: 0)

By default, console output from pckenv does not print a date stamp or log severity.

To enable this functionality, making normal output equivalent to FILE log output, set to 1.

##### `BASHLOG_FILE`

Integer (Default: 0)

Set to 1 to enable plain text logging to file (FILE type logging).

The default path for log files is defined by /tmp/$(basename $0).log
Each executable logs to its own file.

e.g.

```console
$ BASHLOG_FILE=1 pckenv use latest
```

will log to `/tmp/pckenv-use.log`

##### `BASHLOG_FILE_PATH`

String (Default: /tmp/$(basename ${0}).log)

To specify a single file as the target for all FILE type logging regardless of the executing script.

##### `BASHLOG_I_PROMISE_TO_BE_CAREFUL_CUSTOM_EVAL_PREFIX`

String (Default: "")

*BE CAREFUL - MISUSE WILL DESTROY EVERYTHING YOU EVER LOVED*

This variable allows you to pass a string containing a command that will be executed using `eval` in order to produce a prefix to each console output line, and each FILE type log entry.

e.g.

```console
$ BASHLOG_I_PROMISE_TO_BE_CAREFUL_CUSTOM_EVAL_PREFIX='echo "${$$} "'
```
will prefix every log line with the calling process' PID.

##### `BASHLOG_JSON`

Integer (Default: 0)

Set to 1 to enable JSON logging to file (JSON type logging).

The default path for log files is defined by /tmp/$(basename $0).log.json
Each executable logs to its own file.

e.g.

```console
$ BASHLOG_JSON=1 pckenv use latest
```

will log in JSON format to `/tmp/pckenv-use.log.json`

JSON log content:

`{"timestamp":"<date +%s>","level":"<log-level>","message":"<log-content>"}`

##### `BASHLOG_JSON_PATH`

String (Default: /tmp/$(basename ${0}).log.json)

To specify a single file as the target for all JSON type logging regardless of the executing script.

##### `BASHLOG_SYSLOG`

Integer (Default: 0)

To log to syslog using the `logger` binary, set this to 1.

The basic functionality is thus:

```console
$ local tag="${BASHLOG_SYSLOG_TAG:-$(basename "${0}")}";
$ local facility="${BASHLOG_SYSLOG_FACILITY:-local0}";
$ local pid="${$}";
$ logger --id="${pid}" -t "${tag}" -p "${facility}.${severity}" "${syslog_line}"
```

##### `BASHLOG_SYSLOG_FACILITY`

String (Default: local0)

The syslog facility to specify when using SYSLOG type logging.

##### `BASHLOG_SYSLOG_TAG`

String (Default: $(basename $0))

The syslog tag to specify when using SYSLOG type logging.

Defaults to the PID of the calling process.



### pckenv use [version]

Switch a version to use

If no parameter is passed, the version to use is resolved automatically via [.packer-version files](#packer-version-file) or [PCKENV\_PACKER\_VERSION environment variable](#pckenv_packer_version) (PCKENV\_PACKER\_VERSION takes precedence), defaulting to 'latest' if none are found.

`latest` is a syntax to use the latest installed version

`latest:<regex>` is a syntax to use latest installed version matching regex (used by grep -e)

`min-required` will switch to the version minimally required by your terraform sources (see above `pckenv install`)

```console
$ pckenv use
$ pckenv use min-required
$ pckenv use 0.7.0
$ pckenv use latest
$ pckenv use latest:^0.8
```

Note: `pckenv use latest` or `pckenv use latest:<regex>` will find the latest matching version that is already installed. If no matching versions are installed, and PCKENV_AUTO_INSTALL is set to `true` (which is the default) the the latest matching version in the remote repository will be installed and used.

### pckenv uninstall &lt;version>

Uninstall a specific version of Terraform
`latest` is a syntax to uninstall latest version
`latest:<regex>` is a syntax to uninstall latest version matching regex (used by grep -e)

```console
$ pckenv uninstall 0.7.0
$ pckenv uninstall latest
$ pckenv uninstall latest:^0.8
```

### pckenv list

List installed versions

```console
$ pckenv list
* 1.8.7 (set by /opt/pckenv/version)
  1.7.0
  1.5.0
  1.2.2
  1.2.1
  1.2.0
  1.1.3
  1.1.2
  1.1.1
```

### pckenv list-remote

List installable versions

```console
$ pckenv list-remote
1.8.7 
1.8.6
1.8.5
1.8.4
1.8.3
1.8.2
1.8.1
1.8.0
1.7.10
...
```

## .packer-version file

If you put a `.packer-version` file on your project root, or in your home directory, pckenv detects it and uses the version written in it. If the version is `latest` or `latest:<regex>`, the latest matching version currently installed will be selected.

Note, that [PCKENV\_PACKER\_VERSION environment variable](#pckenv_packer_version) can be used to override version, specified by `.packer-version` file.

```console
$ cat .packer-version
1.7.10

$ packer version
Packer v1.7.10

Your version of Packer is out of date! The latest version
is 1.7.10. You can update by downloading from www.packer.io

$ echo 1.8.0 > .packer-version

$ packer version
Terraform v1.8.0

$ echo latest:^8.0 > .packer-version

$ packer version
Packer v1.8.0

$ PCKENV_PACKER_VERSION=1.8.0 packer --version
Packer v1.8.0
```

## Upgrading

```console
$ git --git-dir=~/.pckenv/.git pull
```

## Uninstalling

```console
$ rm -rf /some/path/to/pckenv
```

## LICENSE

- [tfenv itself](https://github.com/tfutils/tfenv/blob/master/LICENSE)
- [rbenv](https://github.com/rbenv/rbenv/blob/master/LICENSE)
- tfenv partially uses rbenv's source code