# orbi-gathering

A modern companion app for physical Magic: The Gathering, focused on game-state management, deck organization, and an intuitive tabletop experience.

See the [project documentation](docs/README.md) for the product vision, gameplay model, architecture, technology decisions, and roadmap.

## Development

The project uses [mise](https://mise.jdx.dev/) for Flutter and Lefthook versions as well as common development tasks.

After cloning and generating the Flutter application:

```sh
mise install
mise run setup
```

Common commands:

```sh
mise run format       # Apply Dart formatting
mise run analyze      # Run static analysis
mise run test         # Run unit and widget tests
mise run check        # Verify formatting, analysis, and tests
mise run doctor       # Inspect the local Flutter toolchain
mise run pr:create    # Create a PR using the latest Conventional Commit message
```

Commits follow the Conventional Commits format, for example
`feat(game): add life tracking`. The commit hook validates this format, and
`mise run pr:create` uses the latest commit message to prefill the pull request
title while retaining the repository pull request template as the body. For a
branch such as `feat/123-game-setup`, it also adds `Closes #123` to link and
close the issue when the pull request merges.

## Running the application

OrbiGathering currently targets Android and iOS. Flutter cannot run this project on Windows, Chrome, or Edge unless those platforms are deliberately added to the project.

### Windows and Android

Windows development requires either an Android emulator or a physical Android phone. Android Studio and its Android SDK are installed separately on each development machine.

To use an emulator, create and start an Android Virtual Device in Android Studio's **Device Manager**, then verify that Flutter can see it:

```powershell
mise run emulators
mise run devices
mise dev
```

You can launch an emulator from PowerShell when you know its ID:

```powershell
mise run emulators -- --launch <emulator-id>
mise dev
```

To use a physical Android phone, enable **Developer options** and **USB debugging**, connect the phone over USB, accept the debugging authorization prompt, and run:

```powershell
mise run devices
mise dev
```

If more than one device is available, target one explicitly:

```powershell
mise dev -- -d <device-id>
```

If Flutter reports that only Windows or web devices are available, start an Android emulator or connect an authorized Android phone. Do not run `flutter create .` solely to make those unsupported devices appear; that would expand the platform scope.

### iOS

iOS development requires macOS and Xcode. Use either an iOS Simulator started from Xcode or an authorized physical iPhone connected to the Mac. Then run:

```sh
mise run devices
mise dev
```

The iOS simulator and iOS build tools are not available from Windows 11.
