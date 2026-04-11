import SwiftUI

struct ContentView: View {
    @AppStorage("hasAgreedToDisclaimer") private var hasAgreed: Bool = false
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            if hasAgreed {
                HomeView()
                    .opacity(showsSplash ? 0 : 1)
            } else {
                DisclaimerView()
                    .opacity(showsSplash ? 0 : 1)
            }

            if showsSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard showsSplash else { return }
            try? await Task.sleep(for: .seconds(1.9))
            withAnimation(.easeOut(duration: 0.35)) {
                showsSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}

struct SplashScreenView: View {
    @State private var animatePulse = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.10, blue: 0.18),
                    Color(red: 0.09, green: 0.20, blue: 0.33),
                    Color.rrDarkAccentText.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 210, height: 210)
                        .scaleEffect(animatePulse ? 1.08 : 0.92)
                        .blur(radius: 2)

                    Circle()
                        .stroke(Color.red.opacity(0.24), lineWidth: 20)
                        .frame(width: 176, height: 176)
                        .scaleEffect(animatePulse ? 1.02 : 0.96)

                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.rrSectionBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 122, height: 122)
                        .overlay(
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.22), radius: 20, y: 10)

                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    VStack(spacing: 6) {
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<6, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(index == 2 || index == 3 ? Color.red.opacity(0.92) : Color.white.opacity(0.78))
                                    .frame(width: 12, height: index.isMultiple(of: 2) ? 18 : 30)
                            }
                        }
                    }
                    .frame(width: 170, height: 170)
                    .offset(y: 44)
                }
                .overlay(alignment: .center) {
                    ECGTrace()
                        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 250, height: 84)
                        .offset(y: 86)
                }
                .scaleEffect(animateContent ? 1 : 0.94)
                .opacity(animateContent ? 1 : 0)

                VStack(spacing: 10) {
                    Text("Rapid Response")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Hospital bedside reference for urgent deterioration")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .multilineTextAlignment(.center)


                }
                .padding(.top, 52)
                .padding(.horizontal, 24)
                .offset(y: animateContent ? 0 : 16)
                .opacity(animateContent ? 1 : 0)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                animateContent = true
            }

            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

private struct SplashBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.12))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private struct ECGTrace: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width

        path.move(to: CGPoint(x: 0, y: midY))
        path.addLine(to: CGPoint(x: width * 0.18, y: midY))
        path.addLine(to: CGPoint(x: width * 0.26, y: midY - 8))
        path.addLine(to: CGPoint(x: width * 0.31, y: midY + 12))
        path.addLine(to: CGPoint(x: width * 0.38, y: midY - 32))
        path.addLine(to: CGPoint(x: width * 0.44, y: midY + 18))
        path.addLine(to: CGPoint(x: width * 0.5, y: midY))
        path.addLine(to: CGPoint(x: width * 0.68, y: midY))
        path.addLine(to: CGPoint(x: width * 0.74, y: midY - 6))
        path.addLine(to: CGPoint(x: width * 0.8, y: midY + 8))
        path.addLine(to: CGPoint(x: width, y: midY))

        return path
    }
}
