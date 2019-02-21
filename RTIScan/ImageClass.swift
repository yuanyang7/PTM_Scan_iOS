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
    

    
    
    let toProcessImage : [RTIImage]
    
    init(toProcessImage: [RTIImage], imageNum : Int, imageWidth : Int, imageHeight : Int) {
        self.toProcessImage = toProcessImage
        self.imageNum = imageNum
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        
        //initialized matrix
        self.vectorX = [Vector](repeating: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], count: imageWidth*imageHeight*imageNum)
        let temp = [Double](repeating: 0.0, count: imageNum)
        self.vectorY = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)

        //self.vectorY_G = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)
        //self.vectorY_B = [Vector](repeating: temp, count: imageWidth*imageHeight*imageNum)
        
    }
    
    func normalizedLight() {
        for (_, image) in toProcessImage.enumerated() {
            image.lightPositionZ = sqrt(image.lightPositionX * image.lightPositionX
                                      + image.lightPositionY * image.lightPositionY)
            //todo: normalized mag
            image.lightPositionX /= image.lightPositionZ
            image.lightPositionY /= image.lightPositionZ
            image.lightPositionZ = 1
        }
    }
    
    func calcMatrix() {
        
       
        for index in 0..<imageNum {
            
            print("Processing image", index)
            
            //matrixA
            var doubleTemp = [Double]()
            let lu = toProcessImage[index].lightPositionX
            let lv = toProcessImage[index].lightPositionY
            doubleTemp.append(Double(lu * lu))
            doubleTemp.append(Double(lv * lv))
            doubleTemp.append(Double(lu * lv))
            doubleTemp.append(Double(lu))
            doubleTemp.append(Double(lv))
            doubleTemp.append(Double(1))
            matrixA.append(doubleTemp)
            
            //matrixY
            //?
            for x in 0..<imageWidth {
                for y in 0..<imageHeight {
                    var redval: CGFloat = 0
                    var greenval: CGFloat = 0
                    var blueval: CGFloat = 0
                    var alphaval: CGFloat = 0
                    let pixelValue = toProcessImage[index].photoImage.getPixelColor(pos: CGPoint(x: x, y: y))
                    pixelValue.getRed(&redval, green: &greenval, blue: &blueval, alpha: &alphaval)
                    vectorY[x * imageHeight * 3 + y * 3][index] = Double(redval)
                    vectorY[x * imageHeight * 3 + y * 3 + 1][index] = Double(greenval)
                    vectorY[x * imageHeight * 3 + y * 3 + 2][index] = Double(blueval)
                }
            }
        }
        
        print("matrix calculation done.")
        
        var u : Matrix
        var s : Matrix
        var v : Matrix
        
        (u,s,v) = svd(inputMatrix: matrixA)
        print("svd calculation done.")
        print(s)
        print("u", u)
        print("y", vectorY[0])
        //https://blog.csdn.net/qq_xuanshuang/article/details/79639240
        //todo
        
        print("calculate coefficients...")
        for x in 0..<imageWidth {
            for y in 0..<imageHeight {
                for c in 0...2 {
                    var B : Matrix
                    let tempIndex = x * imageHeight * 3 + y * 3 + c
                    B = matMul(mat1: transpose(inputMatrix: v), mat2: [vectorY[tempIndex]])
                     for index in 0..<6 {
                        vectorX[tempIndex][index] = B[0][index] / s[index][index]
                        }
                    
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
