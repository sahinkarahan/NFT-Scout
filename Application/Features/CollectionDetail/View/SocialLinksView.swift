import SwiftUI

struct SocialLinksView: View {
    let links: [(icon: String, url: String)]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(links, id: \.url) { link in
                    Button {
                        if let url = URL(string: link.url) {
                            #if os(iOS)
                            UIApplication.shared.open(url)
                            #endif
                        }
                    } label: {
                        socialLinkButton(for: link.icon)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func socialLinkButton(for icon: String) -> some View {
        VStack {
            switch icon.lowercased() {
            case "twitter":
                Image(systemName: "bird.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.circle)
            case "discord":
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.circle)
            case "globe":
                Image(systemName: "globe")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.circle)
            case "instagram":
                Image(systemName: "camera.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.circle)
            case "link", "opensea":
                Image(systemName: "link")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.circle)
            default:
                Image(systemName: "link")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(.circle)
            }
        }
    }
}

#Preview {
    SocialLinksView(links: [
        (icon: "twitter", url: "https://twitter.com/BoredApeYC"),
        (icon: "discord", url: "https://discord.gg/bayc"),
        (icon: "globe", url: "https://boredapeyachtclub.com"),
        (icon: "link", url: "https://opensea.io/collection/boredapeyachtclub")
    ])
    .background(Color.appPrimary)
    .padding()
} 