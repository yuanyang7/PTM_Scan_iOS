//
//  RenderViewController.swift
//  RTIScan
//
//  Created by yang yuan on 1/27/19.
//  Copyright © 2019 Yuan Yang. All rights reserved.
//

import GLKit
import UIKit

extension Array {
    func size() -> Int {
        return MemoryLayout<Element>.stride * self.count
    }
}

class RenderViewController: GLKViewController {
    private var context: EAGLContext?
    
    var Vertices = [
        Vertex(x:  1, y: -1, z: 0, r: 1, g: 0, b: 0, a: 1),
        Vertex(x:  1, y:  1, z: 0, r: 0, g: 1, b: 0, a: 1),
        Vertex(x: -1, y:  1, z: 0, r: 0, g: 0, b: 1, a: 1),
        Vertex(x: -1, y: -1, z: 0, r: 0, g: 0, b: 0, a: 1),
        ]
    
    var Indices: [GLubyte] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    //element buffer object
    private var ebo = GLuint()
    private var vbo = GLuint()
    private var vao = GLuint()
    
    //create an effect
    private var effect = GLKBaseEffect()
    
    private var rotation: Float = 0.0
    
    
    private func setupGL() {
        // 1
        context = EAGLContext(api: .openGLES3)
        // 2
        EAGLContext.setCurrent(context)
        
        if let view = self.view as? GLKView, let context = context {
            // 3
            view.context = context
            // 4
            delegate = self
        }
        
        //helper variables
        // 1
        let vertexAttribColor = GLuint(GLKVertexAttrib.color.rawValue)
        // 2
        let vertexAttribPosition = GLuint(GLKVertexAttrib.position.rawValue)
        // 3
        let vertexSize = MemoryLayout<Vertex>.stride
        // 4
        let colorOffset = MemoryLayout<GLfloat>.stride * 3
        // 5
        let colorOffsetPointer = UnsafeRawPointer(bitPattern: colorOffset)
        
        //creating VOA buffer
        // 1
        glGenVertexArraysOES(1, &vao)
        // 2
        glBindVertexArrayOES(vao)
        
        //Creating VBO Buffers
        glGenBuffers(1, &vbo)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vbo)
        glBufferData(GLenum(GL_ARRAY_BUFFER), // 1
            Vertices.size(),         // 2
            Vertices,                // 3
            GLenum(GL_STATIC_DRAW))  // 4
        
        
        
        glEnableVertexAttribArray(vertexAttribPosition)
        glVertexAttribPointer(vertexAttribPosition,       // 1
            3,                          // 2
            GLenum(GL_FLOAT),           // 3
            GLboolean(UInt8(GL_FALSE)), // 4
            GLsizei(vertexSize),        // 5
            nil)                        // 6
        
        glEnableVertexAttribArray(vertexAttribColor)
        glVertexAttribPointer(vertexAttribColor,
                              4,
                              GLenum(GL_FLOAT),
                              GLboolean(UInt8(GL_FALSE)),
                              GLsizei(vertexSize),
                              colorOffsetPointer)
        
        
        
        //Creating EBO Buffers
        glGenBuffers(1, &ebo)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), ebo)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER),
                     Indices.size(),
                     Indices,
                     GLenum(GL_STATIC_DRAW))
        
        glBindVertexArrayOES(0)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
    }
    
    //clean up buffer
    private func tearDownGL() {
        EAGLContext.setCurrent(context)
        
        glDeleteBuffers(1, &vao)
        glDeleteBuffers(1, &vbo)
        glDeleteBuffers(1, &ebo)
        
        EAGLContext.setCurrent(nil)
        
        context = nil
    }
    
    deinit {
        tearDownGL()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
    }
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // 1
        glClearColor(0.85, 0.85, 0.85, 1.0)
        // 2
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        effect.prepareToDraw()
        
        //draw
        glBindVertexArrayOES(vao);
        glDrawElements(GLenum(GL_TRIANGLES),     // 1
            GLsizei(Indices.count),   // 2
            GLenum(GL_UNSIGNED_BYTE), // 3
            nil)                      // 4
        glBindVertexArrayOES(0)
    }
    @IBAction func backToLastView() {
        print("Back!")
        self.dismiss(animated: true, completion: nil)
    }
    

    
    

}


extension RenderViewController: GLKViewControllerDelegate {
    
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        // 1
        let aspect = fabsf(Float(view.bounds.size.width) / Float(view.bounds.size.height))
        // 2
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 4.0, 10.0)
        // 3
        effect.transform.projectionMatrix = projectionMatrix
        
        // 1
        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -6.0)
        // 2
        rotation += 90 * Float(timeSinceLastUpdate)
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), 0, 0, 1)
        // 3
        effect.transform.modelviewMatrix = modelViewMatrix
    }
}

/*
class RenderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
*/
