//
//  ImageClass.swift
//  RTIScan
//
//  Created by yang yuan on 2/17/19.
//  Copyright © 2019 Yuan Yang. All rights reserved.
//

import Foundation
import UIKit

import Foundation
import Accelerate


extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.x)) + Int(pos.y)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: 0.0)
    }
    
}

//images
class RTIImage {
    
    var photoImage : UIImage
    var lightPositionX : CGFloat
    var lightPositionY : CGFloat
    var lightPositionZ : CGFloat
    
    
    init(photoImage : UIImage) {
        self.photoImage = photoImage
        self.lightPositionX = 0.0
        self.lightPositionY = 0.0
        self.lightPositionZ = 0.0
    }
    
}


//store
class RenderImgtoFile {
    var pixels : [[Double]]
    /*
    init(imageWidth : Int, imageHeight : Int, light_count : Int) {
        let pixels_tmp = [UInt8](repeating: 0, count: imageWidth*imageHeight*3)
        self.pixels = [[UInt8]](repeating: pixels_tmp, count: light_count)
    }
     */
    init(imageWidth : Int, imageHeight : Int) {
        self.pixels = [[Double]](repeating: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], count: imageWidth*imageHeight*3)
    }
    func store(fileName : String) {
        /*
        let fileUrl = NSURL(fileURLWithPath: fileName + ".rti") // Your path here

        // Save to file
        (self.pixels as NSArray).write(to: fileUrl as URL, atomically: true)
        print("rti file saved!")
         */
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = dir.appendingPathComponent(fileName + ".rti")
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: self.pixels, format: .binary, options: 0)
                try data.write(to: url, options: .atomic)
            }
            catch { print(error) }
        }
    
    }
    func read(fileName : String) {
        /*
        let fileUrl = NSURL(fileURLWithPath: fileName + ".rti") // Your path here
        print("reading rti file...")
        // Read from file
        _ = NSArray(contentsOf: fileUrl as URL) as! [[String]]
        */
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let url = dir.appendingPathComponent(fileName + ".rti")
            do {
                let data = try Data(contentsOf: url) 
                self.pixels = try PropertyListSerialization.propertyList(from: data, format: nil) as! [[Double]]
                /*
                for (index, section) in sections.enumerated() {
                    print("section ", index)
                    /*
                    if index == 0{
                        self.pixels = section
                    }
                    else{
                        self.crcy = section
                    }
                    */
                }*/
            }
            catch { print(error) }
        }
        
    }
}

class ProcessingImage {
    
    //test
    typealias Matrix = Array<[Double]>
    typealias Vector = [Double]
    
    var matrixA = Matrix() //nums * 6 just one
    var vectorX : [Vector] //6 [height*width*channel]
    var vectorY : [Vector] //nums [height*width*channel]
    
    let imageNum : Int
    let imageWidth : Int
    let imageHeight : Int
    
    var LightXRender = 0.5
    var LightYRender = 0.5
    
    var RenderingImgtoFile : RenderImgtoFile
    var flagFinishRender : Bool = false
    var renderingBufferCount : Int = 5
    var renderingBufferStep : Double = 0.4
    
    var unscaledColor : [Double]
    
    var bias : [Double]
    var scale : [Double]
    

    
    
    let toProcessImage : [RTIImage]
    
    init(toProcessImage: [RTIImage], imageNum : Int, imageWidth : Int, imageHeight : Int) {
        self.toProcessImage = toProcessImage
        self.imageNum = imageNum
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        
        //initialized matrix
        let temp = [Double](repeating: 0.0, count: imageNum)
        self.matrixA = Matrix(repeating: temp, count: 6)
        self.vectorX = [Vector](repeating: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], count: imageWidth*imageHeight*3)

        self.vectorY = [Vector](repeating: temp, count: imageWidth*imageHeight*3)
        
        self.unscaledColor = [Double](repeating: 0.0, count: imageWidth*imageHeight*3)
        /*
        self.RenderingImgtoFile = RenderImgtoFile(imageWidth : self.imageWidth, imageHeight : self.imageHeight, light_count : self.renderingBufferCount * self.renderingBufferCount)
        */
        //verctorX
        self.RenderingImgtoFile = RenderImgtoFile(imageWidth : self.imageWidth, imageHeight : self.imageHeight)
        
        self.scale = [1, 1, 1, 1, 1, 1]
        self.bias = [0, 0, 0, 0, 0, 0]

        //self.vectorY_G = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)
        //self.vectorY_B = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)
        
    }
    
    func normalizedLight() {
        for (_, image) in toProcessImage.enumerated() {
            image.lightPositionX /= CGFloat(50.0)
            image.lightPositionY /= CGFloat(50.0)
            print(image.lightPositionX, image.lightPositionY)
            
            /*
            image.lightPositionZ = sqrt(image.lightPositionX * image.lightPositionX
                                      + image.lightPositionY * image.lightPositionY)
            //todo: normalized mag
            image.lightPositionX /= image.lightPositionZ
            image.lightPositionY /= image.lightPositionZ
            image.lightPositionZ = 1
            */
        }
    }
    func renderImageResult(l_u_raw : Double, l_v_raw : Double) {
        /*
        var l_u = l_u_raw / 50 + 1
        var l_v = l_v_raw / 50 + 1
        l_u /= self.renderingBufferStep
        l_v /= self.renderingBufferStep
        print("l position", l_u, l_v)
        var rgba = RGBA(image: toProcessImage[0].photoImage)!
        print("image size", rgba.width, imageWidth)
        for x in 0..<imageHeight{
            for y in 0..<imageWidth {
                let index = x * rgba.width + y
                var pixel = rgba.pixels[index]
                pixel.red = self.RenderingImgtoFile.pixels[Int(l_u) * self.renderingBufferCount + Int(l_v)][x * imageWidth * 3 + y * 3]
                pixel.green = self.RenderingImgtoFile.pixels[Int(l_u) * self.renderingBufferCount + Int(l_v)][x * imageWidth * 3 + y * 3 + 1]
                pixel.blue = self.RenderingImgtoFile.pixels[Int(l_u) * self.renderingBufferCount + Int(l_v)][x * imageWidth * 3 + y * 3 + 2]
                //pixel.green = self.RenderingImgtoFile.pixels[Int(l_u) * self.renderingBufferCount + Int(l_v)][x * imageWidth * 3 + y * 3 + 1]
                //pixel.blue = self.RenderingImgtoFile.pixels[Int(l_u) * self.renderingBufferCount + Int(l_v)][x * imageWidth * 3 + y * 3 + 2]
                rgba.pixels[index] = pixel
            }
        }
        
        toProcessImage[0].photoImage = rgba.toUIImage()!
         */
        
    }
    func renderImageFUll() {
        for l_u in stride(from: -1, to: 1, by: self.renderingBufferStep) {
            for l_v in stride(from: -1, to: 1, by: self.renderingBufferStep) {
                let tmp =  ((l_u + 1) / self.renderingBufferStep) * Double(self.renderingBufferCount)
                let l_index = Int( tmp + (l_v + 1) / self.renderingBufferStep)
                print("picels store in", l_index)
                for x in 0..<imageHeight{
                    for y in 0..<imageWidth {
                        //todo!!!!!matrix
                        let light_matrix = Vector(arrayLiteral: l_u * l_u, l_v * l_v, l_u * l_v, l_u, l_v, 1)
                        let redm = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 0]])
                        //let greenm = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 1]])
                        //let bluem = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 2]])
                        
                        //var lu: Double = Double(redm[0][0] * 255)
                        
                        //ycc to rgb todo scale bias
                        //print("co", vectorX[x * imageWidth * 3 + y * 3 + 0])
                        //print("light, ", redm[0][0] * 255)
                        var redd:Double =  Double( vectorY[x * imageWidth * 3 + y * 3 + 2][0] / 0.6350 + redm[0][0] )
                        var blued:Double = Double( vectorY[x * imageWidth * 3 + y * 3 + 1][0] / 0.5389 + redm[0][0] )
                        var greend:Double = redm[0][0] - 0.2126*redd + 0.0722*blued
                        var red:Int = Int(redd * 255)
                        var green:Int = Int(greend * 255)
                        var blue:Int = Int(blued * 255)
                        //print("rgb", red, green, blue)
                        
                        """
                        var red:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3])
                        var green:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 1])
                        var blue:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 2])
                        """
                        //var green:Int = Int(greenm[0][0] * 255)
                        //var blue:Int = Int(bluem[0][0] * 255)
                        //print(red, green, blue)
                        if red < 0{
                            red = 0
                        }
                        if red > 255{
                            red = 255
                            
                        }
                        
                        if green < 0 {
                            green = 0
                            
                        }
                        if green > 255{
                            green = 255
                            
                        }
                        if blue < 0{
                            blue = 0
                        }
                        if blue > 255{
                            blue = 255
                            
                        }
                        
                        
                        /*
                        self.RenderingImgtoFile.pixels[l_index][x * imageWidth * 3 + y * 3] = UInt8(red)
                        self.RenderingImgtoFile.pixels[l_index][x * imageWidth * 3 + y * 3 + 1] = UInt8(green)
                        self.RenderingImgtoFile.pixels[l_index][x * imageWidth * 3 + y * 3 + 2] = UInt8(blue)
                        */
                    }
                }
            }
        }
        
        self.flagFinishRender = true
    }
    
    func renderImage(){
        var rgba = RGBA(image: toProcessImage[0].photoImage)!
        for x in 0..<imageHeight{
            for y in 0..<imageWidth {
                var l_u = LightXRender
                var l_v = LightYRender
                let index = x * rgba.width + y
                var pixel = rgba.pixels[index]
                //todo!!!!!matrix
                let light_matrix = Vector(arrayLiteral: l_u * l_u, l_v * l_v, l_u * l_v, l_u, l_v, 1)
                let lum = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 0]])
                
                var lu: Double = Double(lum[0][0] * 255)
                var red:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3])
                var green:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 1])
                var blue:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 2])
                /*
                if lu < 0{
                    lu = 0
                }
                if lu > 255{
                    lu = 255
                    
                }
                 */
                if red < 0 {
                    red = 0
                    
                }
                if red > 255{
                    red = 255
                    
                }
                if green < 0 {
                    green = 0
                    
                }
                if green > 255{
                    green = 255
                    
                }
                if blue < 0{
                    blue = 0
                }
                if blue > 255{
                    blue = 255
                    
                }
                //print(red)
                //print("1, ",pixel, pixel.red )
                pixel.red = UInt8(red)
                pixel.green = UInt8(green)
                pixel.blue = UInt8(blue)
                //print("red", red, pixel.red)
                
                
                rgba.pixels[index] = pixel
                //print(pixel, pixel.red)
                
                toProcessImage[0].photoImage = rgba.toUIImage()!
            }
        }
    }
    
    func calcMatrix() {
        
       
        for index in 0..<imageNum {
            
            print("Processing image", index)
            
            //matrixA
            let lu = toProcessImage[index].lightPositionX
            let lv = toProcessImage[index].lightPositionY
            print("lu and lv", lu, lv)
            matrixA[0][index] = Double(lu * lu)
            matrixA[1][index] = Double(lv * lv)
            matrixA[2][index] = Double(lu * lv)
            matrixA[3][index] = Double(lu)
            matrixA[4][index] = Double(lv)
            matrixA[5][index] = Double(1.0)
            /*
            var doubleTemp = [Double]()
            let lu = toProcessImage[index].lightPositionX
            let lv = toProcessImage[index].lightPositionY
            doubleTemp.append(Double(lu * lu))
            doubleTemp.append(Double(lv * lv))
            doubleTemp.append(Double(lu * lv))
            doubleTemp.append(Double(lu))
            doubleTemp.append(Double(lv))
            doubleTemp.append(Double(1.0))
            matrixA.append(doubleTemp)
             */
            
            //matrixY
            //?
            for x in 0..<imageHeight {
                for y in 0..<imageWidth {
                    var redval: CGFloat = 0
                    var greenval: CGFloat = 0
                    var blueval: CGFloat = 0
                    var alphaval: CGFloat = 0
                    let pixelValue = toProcessImage[index].photoImage.getPixelColor(pos: CGPoint(x: x, y: y))
                    pixelValue.getRed(&redval, green: &greenval, blue: &blueval, alpha: &alphaval)
                    //luminance (0.2126*R + 0.7152*G + 0.0722*B
                    //to ycc
                    vectorY[x * imageWidth * 3 + y * 3][index] = Double(redval) * 0.2126 + Double(greenval) * 0.7152 + Double(blueval) * 0.0722
                    vectorY[x * imageWidth * 3 + y * 3 + 1][index] = 0.5389 * (Double(blueval) - vectorY[x * imageWidth * 3 + y * 3][index])
                    vectorY[x * imageWidth * 3 + y * 3 + 2][index] = 0.6350 * (Double(redval) - vectorY[x * imageWidth * 3 + y * 3][index])

                    //cbcr
                    if index == 0 {
                            vectorX[x * imageWidth * 3 + y * 3 + 1][0] = vectorY[x * imageWidth * 3 + y * 3 + 1][0]
                            vectorX[x * imageWidth * 3 + y * 3 + 2][0] = vectorY[x * imageWidth * 3 + y * 3 + 2][0]
                    }
                    //print("ycc, ", vectorY[x * imageWidth * 3 + y * 3][index], vectorY[x * imageWidth * 3 + y * 3 + 1][index], vectorY[x * imageWidth * 3 + y * 3 + 2][index])
                    //rgb
                    //vectorY[x * imageWidth * 3 + y * 3][index] = Double(redval)
                    //vectorY[x * imageWidth * 3 + y * 3 + 1][index] = Double(greenval)
                    //vectorY[x * imageWidth * 3 + y * 3 + 2][index] = Double(blueval)
                }
            }
            /*
            //unscale color
            for x in 0..<imageHeight {
                for y in 0..<imageWidth {
                    var redval: CGFloat = 0
                    var greenval: CGFloat = 0
                    var blueval: CGFloat = 0
                    var alphaval: CGFloat = 0
                    let pixelValue = toProcessImage[index].photoImage.getPixelColor(pos: CGPoint(x: x, y: y))
                    pixelValue.getRed(&redval, green: &greenval, blue: &blueval, alpha: &alphaval)
                    
                    self.unscaledColor[x * imageWidth * 3 + y * 3] = Double(redval) / vectorY[x * imageWidth * 3 + y * 3][0] //todo improve add all
                    self.unscaledColor[x * imageWidth * 3 + y * 3 + 1] = Double(greenval) / vectorY[x * imageWidth * 3 + y * 3][0]
                    self.unscaledColor[x * imageWidth * 3 + y * 3 + 2] = Double(blueval) / vectorY[x * imageWidth * 3 + y * 3][0]

                }
            }
            */
            
        }
        
        print("matrix calculation done.")
        
        var u : Matrix
        var s : Matrix
        var v : Matrix
        
        (u,s,v) = svd(inputMatrix: matrixA)
        print("svd calculation done.")
        print("s", s)
        print("u", u)
        print("v", v)
        print("y", vectorY[0])
        //https://blog.csdn.net/qq_xuanshuang/article/details/79639240
        //todo
        
        print("calculate coefficients...")
        for x in 0..<imageHeight {
            for y in 0..<imageWidth {
                for c in 0...0 {
                    var B : Matrix
                    let tempIndex = x * imageWidth * 3 + y * 3 + c
                    B = matMul(mat1: transpose(inputMatrix: u), mat2: [vectorY[tempIndex]])
                    //print("B", B)
                     for index in 0..<6 {
                        vectorX[tempIndex][index] = (B[0][index] / s[index][index] + self.bias[index]) * self.scale[index]
                        //todo scale bias
                        
                        }
                    //print(vectorX[tempIndex], matrixA[0])
                    
                }
            }
        }
        self.RenderingImgtoFile.pixels = vectorX

        print("matrix calculation completed")
 
 

        
    }
    
    //utils
    func matMul(mat1:Matrix, mat2:Matrix) -> Matrix {
        if mat1.count != mat2[0].count {
            print("error")
            return []
        }
        let m = mat1[0].count
        let n = mat2.count
        let p = mat1.count
        var mulresult = Vector(repeating: 0.0, count: m*n)
        let mat1t = transpose(inputMatrix: mat1)
        let mat1vec = mat1t.reduce([], {$0+$1})
        let mat2t = transpose(inputMatrix: mat2)
        let mat2vec = mat2t.reduce([], {$0+$1})
        vDSP_mmulD(mat1vec, 1, mat2vec, 1, &mulresult, 1, vDSP_Length(m), vDSP_Length(n), vDSP_Length(p))
        var outputMatrix:Matrix = []
        for i in 0..<m {
            outputMatrix.append(Array(mulresult[i*n..<i*n+n]))
        }
        return transpose(inputMatrix: outputMatrix)
    }
    
    func transpose(inputMatrix: Matrix) -> Matrix {
        let m = inputMatrix[0].count
        let n = inputMatrix.count
        let t = inputMatrix.reduce([], {$0+$1})
        var result = Vector(repeating: 0.0, count: m*n)
        vDSP_mtransD(t, 1, &result, 1, vDSP_Length(m), vDSP_Length(n))
        var outputMatrix:Matrix = []
        for i in 0..<m {
            outputMatrix.append(Array(result[i*n..<i*n+n]))
        }
        return outputMatrix
    }
    
    func svd(inputMatrix:Matrix) -> (u:Matrix, s:Matrix, v:Matrix) {
        let m = inputMatrix[0].count
        let n = inputMatrix.count
        let x = inputMatrix.reduce([], {$0+$1})
        var JOBZ = Int8(UnicodeScalar("A").value)
        var JOBU = Int8(UnicodeScalar("A").value)
        var JOBVT = Int8(UnicodeScalar("A").value)
        var M = __CLPK_integer(m)
        var N = __CLPK_integer(n)
        var A = x
        var LDA = __CLPK_integer(m)
        var S = [__CLPK_doublereal](repeating: 0.0, count: min(m,n))
        var U = [__CLPK_doublereal](repeating: 0.0, count: m*m)
        var LDU = __CLPK_integer(m)
        var VT = [__CLPK_doublereal](repeating: 0.0, count: n*n)
        var LDVT = __CLPK_integer(n)
        let lwork = min(m,n)*(6+4*min(m,n))+max(m,n)
        var WORK = [__CLPK_doublereal](repeating: 0.0, count: lwork)
        var LWORK = __CLPK_integer(lwork)
        var IWORK = [__CLPK_integer](repeating: 0, count: 8*min(m,n))
        var INFO = __CLPK_integer(0)
        if m >= n {
            dgesdd_(&JOBZ, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
        } else {
            dgesvd_(&JOBU, &JOBVT, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &INFO)
        }
        var s = [Double](repeating: 0.0, count: m*n)
        for ni in 0...(min(m,n)-1) {
            s[ni*m+ni] = S[ni]
        }
        var v = [Double](repeating: 0.0, count: n*n)
        vDSP_mtransD(VT, 1, &v, 1, vDSP_Length(n), vDSP_Length(n))
        
        var outputU:Matrix = []
        var outputS:Matrix = []
        var outputV:Matrix = []
        for i in 0..<m {
            outputU.append(Array(U[i*m..<i*m+m]))
        }
        for i in 0..<n {
            outputS.append(Array(s[i*m..<i*m+m]))
        }
        for i in 0..<n {
            outputV.append(Array(v[i*n..<i*n+n]))
        }
        
        return (outputU, outputS, outputV)
    }
}
