import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: WallpaperManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .tint(Theme.accent)
            }
            .padding()

            Divider()

            Form {
                Section("Pixabay API Key") {
                    SecureField("Paste your Pixabay API key", text: $manager.apiKey)
                    Link("Get a free API key at pixabay.com/api/docs",
                         destination: URL(string: "https://pixabay.com/api/docs/")!)
                        .font(.caption)
                }

                Section("Playback") {
                    Picker("Quality", selection: Binding(
                        get: { manager.quality },
                        set: { manager.setQuality($0) }
                    )) {
                        ForEach(PixabayVideo.Quality.allCases) { quality in
                            Text(quality.displayName).tag(quality)
                        }
                    }
                }

                Section("Behavior") {
                    Toggle("Launch at Login", isOn: Binding(
                        get: { manager.launchAtLogin.isEnabled },
                        set: { manager.launchAtLogin.isEnabled = $0 }
                    ))
                    Toggle("Pause while on battery power", isOn: Binding(
                        get: { manager.pauseOnBattery },
                        set: { manager.pauseOnBattery = $0 }
                    ))
                }

                Section {
                    Text("Video content via Pixabay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 380, idealWidth: 420, minHeight: 320)
        .preferredColorScheme(.dark)
    }
}
