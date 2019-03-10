//
//  RenderResViewController.swift
//  RTIScan
//
//  Created by yang yuan on 3/9/19.
//  Copyright © 2019 Yuan Yang. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import simd

struct Uniforms {
    var lightPos: float2
}

class RenderResViewController: UIViewController {
    
    var textureImg: UIImage!
    var textureImg2: UIImage!
    var PImage : ProcessingImage!
    var coefficients_buffer : [[[Float32]]]!
    var lightPos : float2 = [0.0, 0.0]
    var device: MTLDevice!
    
    var metalLayer: CAMetalLayer!
    
    let vertexData: [Float] = [
        -1.0,  1.0, 0.0,
        -1.0, -1.0, 0.0,
        1.0, -1.0, 0.0,
        
        1.0,  1.0, 0.0,
        -1.0,  1.0, 0.0,
        1.0, -1.0, 0.0,
    ]
    
    var vertexBuffer: MTLBuffer!
    
    var pipelineState: MTLRenderPipelineState!
    
    var commandQueue: MTLCommandQueue!
    
    var timer: CADisplayLink!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        metalLayer = CAMetalLayer()          // 1
        metalLayer.device = device           // 2
        metalLayer.pixelFormat = .bgra8Unorm // 3
        metalLayer.framebufferOnly = true    // 4
        metalLayer.frame = view.layer.frame  // 5
        view.layer.addSublayer(metalLayer)   // 6
        
        //let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0]) // 1
        //vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: []) // 2
        
        // 1
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "displayTexture")
        let vertexProgram = defaultLibrary.makeFunction(name: "mapTexture")
        
        // 2
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.sampleCount = 1
        pipelineStateDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // 3
        //pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        catch {
            assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
            return
        }
        commandQueue = device.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(gameloop))
        timer.add(to: RunLoop.main, forMode: .default)
        
        //swipe
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.numberOfTouchesRequired = 2
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        

        
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizer.Direction.right:
                    print("Back!")
                    self.dismiss(animated: true, completion: nil)
            default:
                break
            }
        }
    }

    
    @IBAction func backToLastView() {
        print("Back!")
        self.dismiss(animated: true, completion: nil)
    }
    
    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 104.0/255.0,
            blue: 55.0/255.0,
            alpha: 1.0)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        /// Metal texture to be drawn whenever the view controller is asked to render its view.
        let textureLoader = MTKTextureLoader(device: device)
        // let texture: MTLTexture = try! textureLoader.newTexture(cgImage: textureImg.cgImage!)
        // let texture2: MTLTexture = try! textureLoader.newTexture(cgImage: textureImg2.cgImage!)
        let texture_co1: MTLTexture = texture2D(buffer: self.coefficients_buffer[0])
        let texture_co2: MTLTexture = texture2D(buffer: self.coefficients_buffer[1])
        let texture_co3: MTLTexture = texture2D(buffer: self.coefficients_buffer[2])
        let texture_co4: MTLTexture = texture2D(buffer: self.coefficients_buffer[3])
        let texture_co5: MTLTexture = texture2D(buffer: self.coefficients_buffer[4])
        let texture_co6: MTLTexture = texture2D(buffer: self.coefficients_buffer[5])
        let texture_cb: MTLTexture = texture2D(buffer: self.coefficients_buffer[6])
        let texture_cr: MTLTexture = texture2D(buffer: self.coefficients_buffer[7])
        
        let renderEncoder = commandBuffer
            .makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        //renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture_co1, index: 0)
        renderEncoder.setFragmentTexture(texture_co2, index: 1)
        renderEncoder.setFragmentTexture(texture_co3, index: 2)
        renderEncoder.setFragmentTexture(texture_co4, index: 3)
        renderEncoder.setFragmentTexture(texture_co5, index: 4)
        renderEncoder.setFragmentTexture(texture_co6, index: 5)
        renderEncoder.setFragmentTexture(texture_cb, index: 6)
        renderEncoder.setFragmentTexture(texture_cr, index: 7)
        var uniforms = Uniforms(lightPos: self.lightPos)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        renderEncoder
            .drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        renderEncoder.endEncoding()
        
        
        commandBuffer.present(drawable)
        commandBuffer.commit()



    }
    
    @objc func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
    //generate texture
    public func texture2D(buffer:[[Float32]]) -> MTLTexture {
        
        let width = buffer[0].count
        let weightsDescription = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: width, height: buffer.count, mipmapped: false)
        weightsDescription.usage = [.shaderRead,.shaderWrite,.pixelFormatView,.renderTarget]
        let texture = device.makeTexture(descriptor: weightsDescription)
        for i in 0 ..< buffer.count {
            texture!.replace(region: MTLRegionMake2D(0, i, width, 1), mipmapLevel: 0, withBytes: buffer[i], bytesPerRow: width * 4)
        }
        return texture!
    }
    
    //Touch
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //keyboard
        var location = CGPoint(x:0, y:0)
        
        self.view.endEditing(true)
        
        let touch = touches.first
        
        location = touch!.location(in: self.view)
        //375 x 667
        var x = Float((location.x - 375 / 2.0) / 100)
        var y = Float((location.y - 667 / 2.0) / 100)
        
        if(x > -1 && x < 1 && y > -1 && y < 1 && (x * x + y * y <= 1)){
            lightPos.x = x
            lightPos.y = x
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
