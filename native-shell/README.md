# Teddy OS Native Shell

**Built by Bryt Ma Tech UG**

This directory defines the Version 2.1 migration boundary for replacing the current Electron compatibility shell with a lightweight native host.

## Target responsibilities

The native shell should start the webview or native UI, provide a narrow command bridge, open approved user folders, manage application windows, expose accessibility settings, and report hardware/update status. It must not expose a general-purpose shell or unrestricted filesystem API to the UI.

## Migration sequence

1. Recreate the Teddy launcher and mode center in the native host.
2. Implement a typed bridge for documents, backup, settings, diagnostics, and notifications.
3. Add permission checks and an audit log around every host operation.
4. Run the same Simple, Advanced, and Care smoke tests against the native build.
5. Measure startup RAM, idle RAM, CPU, and application launch time against the Electron build.
6. Make the native shell the default only after it boots and recovers correctly in QEMU and VirtualBox.

## Non-goals

The native shell must not run a model continuously, silently upload files, or allow an assistant to perform destructive operations without deterministic validation and explicit user confirmation.

The current Electron build remains available while this migration is being tested. Removing it before the native replacement is validated would make the release less reliable, not more lightweight.
