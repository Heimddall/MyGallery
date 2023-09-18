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
            pickerController.sourceType = .camera
            pickerController.allowsEditing = true
            pickerController.delegate = self
            self?.present(pickerController, animated: true)
        }
        
        let urlAction = UIAlertAction(title: "withURL", style: .default) { [weak self] _ in
//
            let alert = UIAlertController(title: "Put URL with pic here", message: "", preferredStyle: .alert)

            alert.addTextField { (textField) in
                textField.text = "//"
            }

            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                
                guard let text = textField?.text else {
                    return
                }
                
                let url = URL(string: text)
                if let data = try? Data(contentsOf: url!) {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {[weak self] in
                        self?.saveImage(image!)
                        self?.collectionView.reloadData()
                    }
                }
            
            }))
            
            self?.present(alert, animated: true, completion: nil)
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            var config = PHPickerConfiguration()
            config.selectionLimit = 0
            
            let pickerVC = PHPickerViewController(configuration: config)
            pickerVC.delegate = self
            self?.present(pickerVC, animated: true)
        }
        
        let documentPicker = UIAlertAction(title: "FromDocument", style: .default) { [weak self] _ in
            let documentPickerVC = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: false)
            documentPickerVC.delegate = self
            documentPickerVC.modalPresentationStyle = .formSheet

            self?.present(documentPickerVC, animated: true, completion: nil)
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(cameraAction)
        alert.addAction(galleryAction)
        alert.addAction(documentPicker)
        alert.addAction(urlAction)
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

                        self?.saveImage(image)
                        self?.collectionView.reloadData()
                    }
                }
            }
        }
    }
}

extension GalleryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }

        print(image.size)
        DispatchQueue.main.async {

            self.saveImage(image)
            self.collectionView.reloadData()
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        let url = urls.first
        if let data = try? Data(contentsOf: url!) {
        let image = UIImage(data: data)
            
            DispatchQueue.main.async {
                self.saveImage(image!)
                self.collectionView.reloadData()
            }
        }

        controller.dismiss(animated: true)
        
        return
            }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let picViewController = UIViewController()
        
        picViewController.view.backgroundColor = .white
        
        let picImageView: UIImageView = UIImageView()
        picImageView.frame.size.width = 400
        picImageView.frame.size.height = 400
        picImageView.contentMode = .scaleAspectFit
        picImageView.center = picViewController.view.center
        picImageView.image = imageArray[indexPath.row]
        picViewController.view.addSubview(picImageView)
        
        let closeButton = UIButton()
        closeButton.setTitle("Close", for: .normal)
        closeButton.backgroundColor = .blue
        closeButton.titleLabel?.textColor = .white
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 24)
        closeButton.frame = CGRect.init(x: self.view.frame.width/3.5, y: self.view.frame.height/6, width: 180, height: 50)
        closeButton.layer.cornerRadius = 18
        
        picViewController.view.addSubview(closeButton)
        
//                closeButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
//
//        @objc func buttonAction(_ sender:UIButton!) {
//           print("Button tapped")
        }

        picViewController.modalPresentationStyle = .formSheet
        self.present(picViewController, animated: true)
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
