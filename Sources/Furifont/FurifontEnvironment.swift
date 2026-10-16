// Copyright (c) 2026 arenclissold. SPDX-License-Identifier: MIT
#if canImport(SwiftUI) && canImport(CoreText)
import SwiftUI

private struct FurifontConfigurationKey: EnvironmentKey {
    static let defaultValue: FurifontConfiguration? = nil
}

extension EnvironmentValues {
    var furifontConfiguration: FurifontConfiguration? {
        get { self[FurifontConfigurationKey.self] }
        set { self[FurifontConfigurationKey.self] = newValue }
    }
}

extension View {
    /// Sets the font, readings, and rendering preferences for descendant `FurifontText` views.
    /// An individual view's explicit `configuration:` takes precedence.
    public func furifont(_ configuration: FurifontConfiguration) -> some View {
        environment(\.furifontConfiguration, configuration)
    }
}
#endif
