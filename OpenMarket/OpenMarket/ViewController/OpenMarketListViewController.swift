//
//  OpenMarket - ViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

class OpenMarketListViewController: UIViewController {
  
  @IBOutlet weak var segmentedControl: UISegmentedControl!
  @IBOutlet weak var collectionView: UICollectionView!
  private var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
  
  private var openMarketItems: [ItemList.Item] = []
  private var layoutType: LayoutType = .list
  private let openMarketApiProvider = OpenMarketAPIProvider()
  private var currentPage: Int = 1
  private var isPaging: Bool = false
  private let imageCache = NSCache<NSString, UIImage>()

  //MARK:-Life Cycle Method
  override func viewDidLoad() {
    super.viewDidLoad()
    configureActivityIndicator()
    configureSegmentedControl()
    configureCollectionView()
    fetchProjectItems(page: currentPage)
  }

  //MARK:-Initialize ViewController
  private func fetchProjectItems(page: Int) {
    isPaging = true
    collectionView.isHidden = true
    activityIndicator.startAnimating()
    openMarketApiProvider.getProducts(page: page) { [weak self] result in
      switch result {
      case .success(let items):
        self?.openMarketItems.append(contentsOf: items)
        DispatchQueue.main.async {
          self?.activityIndicator.stopAnimating()
          self?.activityIndicator.isHidden = true
          self?.collectionView.isHidden = false
          self?.collectionView.reloadData()
          self?.isPaging = false
        }
        
        self?.currentPage += 1
      case .failure:
        fatalError()
      }
    }
  }
  
  private func configureActivityIndicator() {
    view.addSubview(activityIndicator)
    activityIndicator.center = view.center
  }
  
  private func configureSegmentedControl() {
    segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.systemBlue], for: .normal)
    segmentedControl.selectedSegmentTintColor = .systemBlue
    segmentedControl.backgroundColor = .white
    segmentedControl.addTarget(self, action: #selector(segmentedControlChangedValue(_:)), for: .valueChanged)
  }
  
  private func configureCollectionView() {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    collectionView.collectionViewLayout = layout
    collectionView.delegate = self
    collectionView.dataSource = self
    
    collectionView.register(UINib(nibName: ItemListCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: ItemListCollectionViewCell.identifier)
    collectionView.register(UINib(nibName: ItemGridCollectionViewCell.identifier, bundle: nil), forCellWithReuseIdentifier: ItemGridCollectionViewCell.identifier)
  }
  
  @objc func segmentedControlChangedValue(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      layoutType = .list
      collectionView.reloadData()
    case 1:
      layoutType = .grid
      collectionView.reloadData()
    default:
      return
    }
  }
}

extension OpenMarketListViewController: UICollectionViewDelegate {
  //MARK:- UIScrollViewDelegate Method for Pagination
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let position = scrollView.contentOffset.y
    if position > (collectionView.contentSize.height-100-scrollView.frame.size.height) {
      if isPaging == true {
        return
      }
      fetchNextPage()
    }
  }
  
  private func fetchNextPage() {
    isPaging = true
    openMarketApiProvider.getProducts(page: currentPage) { [weak self] result in
      switch result {
      case .success(let items):
        guard let currentCellCount = self?.openMarketItems.count else { return }
        self?.openMarketItems.append(contentsOf: items)
        let range = currentCellCount..<currentCellCount + items.count
        DispatchQueue.main.async {
          self?.collectionView.performBatchUpdates({
            let indexPaths = range.map{ IndexPath(item: $0, section: 0) }
            self?.collectionView.insertItems(at: indexPaths)
          })
          self?.currentPage += 1
        }
        self?.isPaging = false
      case .failure:
        fatalError()
      }
    }
  }
}

extension OpenMarketListViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return openMarketItems.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if openMarketItems.isEmpty == true {
      return UICollectionViewCell()
    }
    
    let item = openMarketItems[indexPath.item]
    let keyForCache = NSString(string: String(item.id))
    switch layoutType {
    case .list:
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemListCollectionViewCell.identifier, for: indexPath) as? ItemListCollectionViewCell else {
        return UICollectionViewCell()
      }
      
      if let imageFromCache = imageCache.object(forKey: keyForCache) {
        cell.configureLabels(item: item)
        cell.configureImageView(image: imageFromCache)
      } else {
        cell.configureCell(item: item) { [weak self] image in
          DispatchQueue.main.async {
            self?.imageCache.setObject(image, forKey: keyForCache)
          }
        }
      }
      
      return cell
    case .grid:
      guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemGridCollectionViewCell.identifier, for: indexPath) as? ItemGridCollectionViewCell else {
        return UICollectionViewCell()
      }
      if let imageFromCache = imageCache.object(forKey: keyForCache) {
        cell.configureLabels(item: item)
        cell.configureImageView(image: imageFromCache)
      } else {
        cell.configureCell(item: item) { [weak self] image in
          DispatchQueue.main.async {
            self?.imageCache.setObject(image, forKey: keyForCache)
          }
        }
      }
      
      return cell
    }
  }
}

extension OpenMarketListViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    switch layoutType {
    case .list:
      let cellWidth = collectionView.frame.width
      let cellHeight = collectionView.frame.height / 10
      return CGSize(width: cellWidth, height: cellHeight)
    case .grid:
      let cellWidth = collectionView.frame.width / 2
      let cellHeight = collectionView.frame.height / 3
      return CGSize(width: cellWidth, height: cellHeight)
    }
  }
}

enum LayoutType {
  case list
  case grid
}
