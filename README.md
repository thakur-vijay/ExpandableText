# ExpandableText ✂️

A beautifully crafted SwiftUI package that enables **smooth, animated
text expansion** with native-feeling truncation and blur transitions ---
powered by modern iOS text rendering APIs.

Built for developers who want **pixel-perfect control over text
behavior** without compromising performance or API simplicity.

------------------------------------------------------------------------

## ✨ Why ExpandableText?

ExpandableText is not just a "Read More" solution --- it's a **custom
rendering system for text expansion**.

-   ⚡ Zero boilerplate integration\
-   🎯 Precise line-based truncation\
-   🎬 Smooth animated expansion\
-   🌫 Native blur-based reveal effect\
-   🧠 Built using `TextRenderer` (iOS 18+)\
-   🧩 Clean modifier-based API\
-   🎨 Fully customizable trailing text ("...More")

------------------------------------------------------------------------

## 📱 Demo

<img width="800" height="419" alt="ScreenRecording2026-05-02at1 10 59PM-ezgif com-video-to-gif-converter" src="https://github.com/user-attachments/assets/83584dbf-248f-4a78-954f-205786073f63" />


------------------------------------------------------------------------

## 🚀 Installation

### Swift Package Manager

File → Add Package Dependencies

Or:

https://github.com/thakur-vijay/ExpandableText.git

------------------------------------------------------------------------

## 🛠 Requirements

-   iOS 18.0+\
-   SwiftUI

------------------------------------------------------------------------

## 💡 Usage

``` swift
import SwiftUI
import ExpandableText

struct ContentView: View {
    @State private var isCollapsed = true

    var body: some View {
        Text("Long text goes here...")
            .expandable(
                length: 3,
                isEnabled: isCollapsed,
                moreText: "...More",
                blurRadius: 2,
                animation: .easeInOut
            )
            .onTapGesture {
                isCollapsed.toggle()
            }
    }
}
```

------------------------------------------------------------------------

## ⚙️ Configuration Options

| Parameter   | Description                 |
|------------|-----------------------------|
| `length`    | Number of visible lines     |
| `isEnabled` | Controls collapse state     |
| `moreText`  | Trailing text               |
| `blurRadius`| Blur intensity              |
| `animation` | Transition animation        |

------------------------------------------------------------------------

## 🧠 How It Works

-   Custom `TextRenderer`
-   Line-by-line drawing
-   Blur + opacity animation
-   Injected trailing text

------------------------------------------------------------------------

## 🎯 Best Practices

-   Use 2--4 lines\
-   Keep text short\
-   Use subtle animations

------------------------------------------------------------------------

## 📄 License

MIT License

## ⭐ Support

If you find this project useful:

- ⭐ Star the repository
- 🧃 Or… let users tip you through it 😄

