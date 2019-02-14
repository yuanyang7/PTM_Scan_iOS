//
//  ImagesViewController.swift
//  RTIScan
//
//  Created by yang yuan on 2/9/19.
//  Copyright © 2019 Yuan Yang. All rights reserved.
//

import UIKit
import Gallery
import AVFoundation
import AVKit
import Lightbox
import SVProgressHUD

class ImagesViewController: UIViewController, LightboxControllerDismissalDelegate, GalleryControllerDelegate  {

    var button: UIButton!
    var gallery: GalleryController!
    //var resolvedImages : [UIImage?] = []
    
    func lightboxControllerWillDismiss(_ controller: LightboxController) {
        
    }
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil)
        gallery = nil
    }
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        controller.dismiss(animated: true, completion: nil)
        Image.resolve(images: images, completion: { [weak self] resolvedImages in
            //SVProgressHUD.dismiss()
            //  self?.showCGSizeLightbox(images: resolvedImages.compactMap({ $0 }))
        })
        print("done")
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        LightboxConfig.DeleteButton.enabled = true
        
        SVProgressHUD.show()
        Image.resolve(images: images, completion: { [weak self] resolvedImages in
            SVProgressHUD.dismiss()
            self?.showLightbox(images: resolvedImages.compactMap({ $0 }))
        })
    }
    
    

    func showLightbox(images: [UIImage]) {
        guard images.count > 0 else {
            return
        }
        
        let lightboxImages = images.map({ LightboxImage(image: $0) })
        let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
        lightbox.dismissalDelegate = self
        
        gallery.present(lightbox, animated: true, completion: nil)
    }
    

    @IBOutlet weak var imagePreview: UIImageView!
    
    
    
    @IBAction func importImage(_ sender: Any) {
        let gallery = GalleryController()
        gallery.delegate = self
        present(gallery, animated: true, completion: nil)
    }
 
    
    //single image
    /*
    @IBAction func importImage(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true) {
            //after it is complete
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagePreview.image = image
            print("Previewing selected image")
        }
        else {
            //error message
            print("Error when import images.")
        }
        self.dismiss(animated: true, completion: { () -> Void in
            
        })
    }
 */
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        Gallery.Config.VideoEditor.savesEditedVideoToLibrary = true
        
        button = UIButton(type: .system)
        button.frame.size = CGSize(width: 200, height: 50)
        button.setTitle("Open Gallery", for: UIControl.State())
        button.addTarget(self, action: #selector(buttonTouched(_:)), for: .touchUpInside)
        
        view.addSubview(button)

        // Do any additional setup after loading the view.
    }
    
    @objc func buttonTouched(_ button: UIButton) {
        gallery = GalleryController()
        gallery.delegate = self
        
        present(gallery, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func backToLastView() {
        print("Back!")
        self.dismiss(animated: true, completion: nil)
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
