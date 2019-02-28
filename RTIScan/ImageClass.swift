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
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
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

        //self.vectorY_G = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)
        //self.vectorY_B = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)
        
    }
    
    func normalizedLight() {
        for (_, image) in toProcessImage.enumerated() {
            image.lightPositionX /= CGFloat(50.0)
            image.lightPositionY /= CGFloat(50.0)
            
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
    
    func renderImage(){
        var rgba = RGBA(image: toProcessImage[0].photoImage)!
        for y in 0..<imageHeight{
            for x in 0..<imageWidth {
                var l_u = LightXRender
                var l_v = LightYRender
                let index = y * rgba.width + x
                var pixel = rgba.pixels[index]
                //todo!!!!!matrix
                let light_matrix = Vector(arrayLiteral: l_u * l_u, l_v * l_v, l_u * l_v, l_u, l_v, 1)
                let redm = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 0]])
                let greenm = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 1]])
                let bluem = matMul(mat1: transpose(inputMatrix: [light_matrix]), mat2: [vectorX[x * imageWidth * 3 + y * 3 + 2]])
                //print("pixel", red[0][0] * 255.0, green[0][0] * 255.0, blue[0][0] * 255.0)
                /*
                pixel.red =   UInt8(l_u * l_u * vectorX[x * imageWidth * 3 + y * 3 + 0][0])
                pixel.red = pixel.red + UInt8(l_v * l_v * vectorX[x * imageWidth * 3 + y * 3 + 0][1])
                pixel.red = pixel.red + UInt8(l_u * l_v * vectorX[x * imageWidth * 3 + y * 3 + 0][2])
                pixel.red = pixel.red + UInt8(l_u * vectorX[x * imageWidth * 3 + y * 3 + 0][3])
                pixel.red = pixel.red + UInt8(l_v * vectorX[x * imageWidth * 3 + y * 3 + 0][4])
                pixel.red = pixel.red + UInt8(vectorX[x * imageWidth * 3 + y * 3 + 0][6])
                pixel.green = UInt8(l_u * l_u * vectorX[x * imageWidth * 3 + y * 3 + 1][0])
                pixel.green = pixel.green + UInt8(l_v * l_v * vectorX[x * imageWidth * 3 + y * 3 + 1][1])
                pixel.green = pixel.green + UInt8(l_u * l_v * vectorX[x * imageWidth * 3 + y * 3 + 1][2])
                pixel.green = pixel.green + UInt8(l_u * vectorX[x * imageWidth * 3 + y * 3 + 1][3])
                pixel.green = pixel.green + UInt8(l_v * vectorX[x * imageWidth * 3 + y * 3 + 1][4])
                pixel.green = pixel.green + UInt8(vectorX[x * imageWidth * 3 + y * 3 + 1][6])
                pixel.blue =  UInt8(l_u * l_u * vectorX[x * imageWidth * 3 + y * 3 + 2][0])
                pixel.blue = pixel.blue + UInt8(l_v * l_v * vectorX[x * imageWidth * 3 + y * 3 + 2][1])
                pixel.blue = pixel.blue + UInt8(l_u * l_v * vectorX[x * imageWidth * 3 + y * 3 + 2][2])
                pixel.blue = pixel.blue + UInt8(l_u * vectorX[x * imageWidth * 3 + y * 3 + 2][3])
                pixel.blue = pixel.blue + UInt8(l_v * vectorX[x * imageWidth * 3 + y * 3 + 2][4])
                pixel.blue = pixel.blue + UInt8(vectorX[x * imageWidth * 3 + y * 3 + 2][6])
                */
                
                var red:Int = Int(redm[0][0] * 255)
                var green:Int = Int(greenm[0][0] * 255)
                var blue:Int = Int(bluem[0][0] * 255)
                //print(red, green, blue)
                if red < 0{
                    red = -1 * red
                }
                if red > 255{
                    red = 255
                    
                }
                if green < 0 {
                    green = -1 * green
                    
                }
                if green > 255{
                    green = 255
                    
                }
                if blue < 0{
                    blue = -1 * blue
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
                    vectorY[x * imageWidth * 3 + y * 3][index] = Double(redval)
                    vectorY[x * imageWidth * 3 + y * 3 + 1][index] = Double(greenval)
                    vectorY[x * imageWidth * 3 + y * 3 + 2][index] = Double(blueval)
                }
            }
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
                for c in 0...2 {
                    var B : Matrix
                    let tempIndex = x * imageWidth * 3 + y * 3 + c
                    B = matMul(mat1: transpose(inputMatrix: u), mat2: [vectorY[tempIndex]])
                    //print("B", B)
                     for index in 0..<6 {
                        vectorX[tempIndex][index] = B[0][index] / s[index][index]
                        }
                    //print(vectorX[tempIndex], matrixA[0])
                    
                }
            }
        }
        print("matrix calculation completed")
 
 

        
    }
    
    //test
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
