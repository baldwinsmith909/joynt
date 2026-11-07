import SwiftUI
import PhotosUI

struct ComposerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var note = ""
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                photoBlock
                BlankStickyComposer(text: $note, color: JoyntTheme.stickyYellow)
                BlackPillButton(
                    title: store.isBusy ? "Posting…" : "Post meal",
                    offsetColor: JoyntTheme.coral,
                    isEnabled: image != nil && !store.isBusy
                ) {
                    guard let image else { return }
                    Task {
                        await store.createPost(image: image, note: note)
                        note = ""
                        self.image = nil
                        pickerItem = nil
                    }
                }
                .padding(.top, 8)

                Text("No ratings. No recommend prompt. Photo + optional note.")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.45))
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 8)
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    image = ui
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $image)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("02 / POST")
                .joyntMetaLabel()
            Text("One meal.")
                .joyntPosterType(40)
            Text("A photo is enough. The sticky is optional.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.black.opacity(0.65))
        }
    }

    private var photoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            PosterFrame {
                ZStack {
                    JoyntTheme.creamDeep
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack(spacing: 12) {
                            Circle()
                                .stroke(Color.black, lineWidth: 3)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: "camera")
                                        .font(.system(size: 24, weight: .bold))
                                )
                            Text("ADD PHOTO")
                                .joyntMetaLabel()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .clipped()
            }

            HStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Text("Library")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(JoyntTheme.cream)
                                .overlay(Capsule().stroke(Color.black, lineWidth: 2))
                        )
                }
                Button {
                    showCamera = true
                } label: {
                    Text("Camera")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.black))
                        .background(Capsule().fill(JoyntTheme.mint).offset(x: 3, y: 3))
                }
                .buttonStyle(.plain)

                if image != nil {
                    Button("Clear") {
                        image = nil
                        pickerItem = nil
                    }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.5))
                }
            }
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}
