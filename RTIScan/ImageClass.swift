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
        print("writing size: ", imageWidth, imageHeight)
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
    var imageWidth : Int
    var imageHeight : Int
    
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
    func LocateLight(ballR_in : Int, ballX_in : Int, ballY_in : Int, scale : Double) {
        let ballR = Int(Double(ballR_in) * scale)
        let ballY = Int(Double(ballY_in) * scale)
        let ballX = Int(Double(ballX_in) * scale)
        for index in 0..<imageNum {
            
            var max = 0.0
            let img = toProcessImage[index].photoImage
            let pixelData = img.cgImage!.dataProvider!.data
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            print(ballX, ballY, ballR)
            for x in Int(ballX - ballR)...Int(ballX + ballR){
                for y in Int(ballY - ballR)...Int(ballY + ballR) {
                    let dist_X = (x - ballX) * (x - ballX)
                    let dist_Y = (y - ballY) * (y - ballY)
                    let dist = dist_X + dist_Y
                    if(dist  - ballR * ballR <= 0) {
                        let pixelInfo: Int = ((imageWidth * y) + x) * 4
                        
                        let r = Double(data[pixelInfo])     / Double(255.0)
                        let g = Double(data[pixelInfo + 1]) / Double(255.0)
                        let b = Double(data[pixelInfo + 2]) / Double(255.0)
                        let light = r * 0.2126 + g * 0.7152 + b * 0.0722
                        print(x,y,r,g,b, (Double(x) - Double(ballX)) / (Double(ballR)), (Double(y) - Double(ballY)) / (Double(ballR)))
                        if(max <= light){
                            max = light
                            self.toProcessImage[index].lightPositionX = CGFloat((Double(x) - Double(ballX)) / (Double(ballR)))
                            self.toProcessImage[index].lightPositionY = CGFloat((Double(y) - Double(ballY)) / (Double(ballR)))
                            
                            print(x,y,max)
                        }
                    }
                }
            }
            print(max, toProcessImage[index].lightPositionX , toProcessImage[index].lightPositionY)
        }
    }
    func renderImageResult(l_u_raw : Double, l_v_raw : Double) {

    }
    func renderImageFUll() {
        //deprecated
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
                        let redd:Double = Double( vectorY[x * imageWidth * 3 + y * 3 + 2][0] / 0.6350 + redm[0][0] )
                        let blued:Double = Double( vectorY[x * imageWidth * 3 + y * 3 + 1][0] / 0.5389 + redm[0][0] )
                        
                        let greend:Double = redm[0][0] - 0.2126*redd + 0.0722*blued
                        var red:Int = Int(redd * 255)
                        var green:Int = Int(greend * 255)
                        var blue:Int = Int(blued * 255)
                        //print("rgb", red, green, blue)
                        
                        /*
                        var red:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3])
                        var green:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 1])
                        var blue:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 2])
                        */
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
        ///deprecated
        let rgba = RGBA(image: toProcessImage[0].photoImage)!
        for x in 0..<imageHeight{
            for y in 0..<imageWidth {
                let l_u = LightXRender
                let l_v = LightYRender
                let index = x * rgba.width + y
                var pixel = rgba.pixels[index]
                //todo!!!!!matrix
                let light_matrix = Vector(arrayLiteral: l_u * l_u, l_v * l_v, l_u * l_v, l_u, l_v, 1)
                let lum = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 0]])
                
                let lu: Double = Double(lum[0][0] * 255)
                var red:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3])
                var green:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 1])
                var blue:Int = Int(lu * self.unscaledColor[x * imageWidth * 3 + y * 3 + 2])

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

                pixel.red = UInt8(red)
                pixel.green = UInt8(green)
                pixel.blue = UInt8(blue)
                
                rgba.pixels[index] = pixel
                
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
            
            //matrixY
            let img = toProcessImage[index].photoImage
            let pixelData = img.cgImage!.dataProvider!.data
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            print(index, imageHeight, imageWidth)
            for x in 0..<imageHeight {
                for y in 0..<imageWidth {
                  let pixelInfo: Int = ((imageWidth * x) + y) * 4
                    
                    let r = Double(data[pixelInfo])     / Double(255.0)
                    let g = Double(data[pixelInfo + 1]) / Double(255.0)
                    let b = Double(data[pixelInfo + 2]) / Double(255.0)
    
                    //luminance (0.2126*R + 0.7152*G + 0.0722*B
                    //to ycc
                    vectorY[x * imageWidth * 3 + y * 3][index] = r * 0.2126 + g * 0.7152 + b * 0.0722
  
                    //cbcr
                    if index == 0 {
                        vectorX[x * imageWidth * 3 + y * 3 + 1][0] = 0.5389 * (b - vectorY[x * imageWidth * 3 + y * 3][index])
                        vectorX[x * imageWidth * 3 + y * 3 + 2][0] = 0.6350 * (r - vectorY[x * imageWidth * 3 + y * 3][index])
                    }

                }
            }
            print("end")
            
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
        
        var B : Matrix
        var X1 : Matrix = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]
        var X2 : Matrix = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]]
        for x in 0..<imageHeight {
            for y in 0..<imageWidth {
                for c in 0...0 {
                    let tempIndex = x * imageWidth * 3 + y * 3 + c
                    B = matMul(mat1: transpose(inputMatrix: u), mat2: [vectorY[tempIndex]])
                    for index in 0..<6 {
                        //vectorX[tempIndex][index] = (B[0][index] / s[index][index] + self.bias[index]) * self.scale[index]
                        X1[0][index] = B[0][index] / s[index][index]
                        }
                    X2 = matMul(mat1: v, mat2: X1)
                    vectorX[tempIndex] = X2[0]
                    
                    
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
