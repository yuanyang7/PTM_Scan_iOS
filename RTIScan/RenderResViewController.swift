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

class RenderResViewController: UIViewController {
    
    var textureImg: UIImage!
    var textureImg2: UIImage!
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
        var texture: MTLTexture = try! textureLoader.newTexture(cgImage: textureImg.cgImage!)
        var texture2: MTLTexture = try! textureLoader.newTexture(cgImage: textureImg2.cgImage!)
        let renderEncoder = commandBuffer
            .makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        //renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentTexture(texture2, index: 1)
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
    
    //Touch
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //keyboard
        var location = CGPoint(x:0, y:0)
        
        self.view.endEditing(true)
        
        let touch = touches.first
        
        location = touch!.location(in: self.view)
        //375 x 667
        var x = location.x - 375 / 2.0
        var y = location.y - 667 / 2.0
        
        if(x > -100 && x < 100 && y > -100 && y < 100){
            print(x / 100 ,y / 100)
            
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
