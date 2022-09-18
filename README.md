![MacSymbolicator](/Resources/Assets.xcassets/AppIcon.appiconset/Icon_128x128.png?raw=true)

# MacSymbolicator 2.5
	
A simple Mac app for symbolicating macOS/iOS crash reports.

Supports symbolicating:

- .crash and .ips crash reports
- sample and spindump reports

Includes a command-line interface (`MacSymbolicator.app/Contents/MacOS/MacSymbolicatorCLI`):

```
USAGE: mac-symbolicator-cli [--translate-only] [--verbose] [--output <output>] <report-file-path> [<dsym-path> ...]

ARGUMENTS:
  <report-file-path>      The report file: .crash/.ips for crash reports .txt for samples/spindumps
  <dsym-path>             The dSYMs to use for symbolication

OPTIONS:
  -t, --translate-only    Translate the crash report from .ips to .crash
  -v, --verbose
  -o, --output <output>   The output file to save the result to, instead of printing to stdout
  -h, --help              Show help information.
```

[Download](https://github.com/inket/MacSymbolicator/releases)

<a href="https://www.buymeacoffee.com/mahdibchatnia" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="48" width="173" ></a>

# Screenshots

![MacSymbolicator](/screenshot1.png?raw=true)

![MacSymbolicator](/screenshot2.png?raw=true)

![MacSymbolicator](/screenshot3.png?raw=true)

## Building from source

Just clone and build with Xcode 13+

## License

License is GNU GPLv2.

## Contact

@inket on GitHub/Twitter
