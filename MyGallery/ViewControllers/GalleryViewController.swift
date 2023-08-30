//
//  GalleryViewController.swift
//  MyGallery
//
//  Created by Никита Суровцев on 15.08.23.
//

import UIKit
import PhotosUI

class GalleryViewController: UIViewController {
    
    var imageArray = [UIImage]()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
        registerCell()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    
    func registerCell() {
        let collectionCell = UINib(nibName: "PIcCollectionViewCell", bundle: Bundle.main)
        collectionView.register(collectionCell, forCellWithReuseIdentifier: "collectionViewCell")
    }
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    func showPickingAlert() {
        let alert = UIAlertController(title: "Add photo", message: "Choose app for adding photo", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            let pickerController = UIImagePickerController()
            pickerController.delegate = self as! any UIImagePickerControllerDelegate & UINavigationControllerDelegate
            pickerController.allowsEditing = false
            pickerController.mediaTypes = ["public.image"]
            pickerController.sourceType = .camera
            self?.present(pickerController, animated: true)
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            var config = PHPickerConfiguration()
            config.selectionLimit = 0
            
            let pickerVC = PHPickerViewController(configuration: config)
            pickerVC.delegate = self
            self?.present(pickerVC, animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
    
    @IBAction func addImageToGallery(_ sender: Any) {
        showPickingAlert()
    }
    
    func saveImage(_ image: UIImage) {
        guard let saveDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let imageData = image.pngData() else { return }
        
        let fileName = UUID().uuidString
        
        let fileURL = URL(fileURLWithPath: fileName, relativeTo: saveDirectory).appendingPathExtension("png")
        
        try? imageData.write(to: fileURL)
        
        URLManager.addImageName(fileName)
        
        loadImage(from: fileURL.absoluteURL)
        print("File saved: \(fileURL.absoluteURL)")
    }
    
    func loadImage(from fileURL: URL) {
        guard let savedData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: savedData) else { return }
        
        imageArray.append(image)
        
    }
    
    func loadImage() {
        guard let saveDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        
        let fileNames = URLManager.getImagesNames()
        for fileName in fileNames {
            let fileURL = URL(fileURLWithPath: fileName, relativeTo: saveDirectory).appendingPathExtension("png")
            
            guard let savedData = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: savedData) else { return }
            imageArray.append(image)
        }
    }
    
    func clearImages() {
        URLManager.deleteAll()
        imageArray.removeAll()
        collectionView.reloadData()
    }
    
    @IBAction func clearImagesButton(_ sender: UIButton) {
        clearImages()
    }
}


extension GalleryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true)
        }
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        //                        self?.imageArray.append(image)
                        self?.saveImage(image)
                        self?.collectionView.reloadData()
                    }
                }
            }
        }
    }
}


extension GalleryViewController:UICollectionViewDataSource, UICollectionViewDelegate  {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as? PIcCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.imageViewCell.image = imageArray[indexPath.row]
        return cell
    }
}

extension GalleryViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.size.width / 2 - 2, height: collectionView.frame.size.height / 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}
