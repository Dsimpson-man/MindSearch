import SwiftUI
import MetalKit

/// 一个 metaball（水滴）单元
struct MetaballBlob {
    var center: SIMD2<Float>
    var radius: Float
    var weight: Float
}

/// 用 Metal 画的 metaball 视图：多个球重叠时像水滴一样融合
struct MetaballView: UIViewRepresentable {
    let blobs: [MetaballBlob]
    let tint: SIMD3<Float>

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.framebufferOnly = false
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        let renderer = MetaballRenderer(view: view)
        context.coordinator.renderer = renderer
        view.delegate = renderer
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        // 传进来的是 SwiftUI 的点坐标，shader 里是像素坐标，按屏幕倍率换算
        let scale = Float(view.contentScaleFactor)
        let pixelBlobs = blobs.map { b in
            MetaballBlob(center: b.center * scale, radius: b.radius * scale, weight: b.weight)
        }
        context.coordinator.renderer?.update(blobs: pixelBlobs, tint: tint)
        view.setNeedsDisplay()
    }

    final class Coordinator {
        var renderer: MetaballRenderer?
    }
}

final class MetaballRenderer: NSObject, MTKViewDelegate {
    private var blobs: [MetaballBlob] = []
    private var tint: SIMD3<Float> = SIMD3(0.17, 0.13, 0.10)
    private let pipeline: MTLRenderPipelineState
    private let commandQueue: MTLCommandQueue

    init?(view: MTKView) {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "metaball_vertex"),
              let fragment = library.makeFunction(name: "metaball_fragment"),
              let queue = device.makeCommandQueue() else { return nil }

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertex
        desc.fragmentFunction = fragment
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        do {
            pipeline = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            return nil
        }
        commandQueue = queue
        super.init()
    }

    func update(blobs: [MetaballBlob], tint: SIMD3<Float>) {
        self.blobs = blobs
        self.tint = tint
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard !blobs.isEmpty,
              let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = commandQueue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: rpd) else { return }

        encoder.setRenderPipelineState(pipeline)

        var viewSize = SIMD2<Float>(Float(drawable.texture.width), Float(drawable.texture.height))
        encoder.setFragmentBytes(&viewSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)

        var blobData = blobs
        blobData.withUnsafeMutableBytes { raw in
            if let base = raw.baseAddress {
                encoder.setFragmentBytes(base, length: raw.count, index: 1)
            }
        }
        var count = Int32(blobs.count)
        encoder.setFragmentBytes(&count, length: MemoryLayout<Int32>.stride, index: 2)

        var tint = self.tint
        encoder.setFragmentBytes(&tint, length: MemoryLayout<SIMD3<Float>>.stride, index: 3)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
